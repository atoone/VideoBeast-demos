;
; BOING.COM - Interrupt driven Boing ball
;
;


                OUTPUT  "boing.com"

VBASE           .EQU    04000h
IO_PAGE_1       .EQU    071h      ; Page 1: 4000h - 7fffh
PORT_6789       .EQU    0EF00h
TILE_PAGE       .EQU    028h                        ; Page 40x4 -> 160K. MUST be a multiple of 8

                .INCLUDE "../common/bios_1_6.inc"
                .INCLUDE "../common/videobeast.inc"


                .ORG    0100h

                DI
                LD      (old_stack), SP
                LD      SP, old_stack

                LD      C, 1                        ; Remember what the current page mappings are so we can restore them later
                CALL    MBB_GET_PAGE
                LD      (old_page_1), A
                
                LD      A, VIDEOBEAST_PAGE
                OUT     (IO_PAGE_1), A

                LD      A, (VB_REGISTERS_LOCKED)
                LD      (lock_status), A

                LD      A, VB_UNLOCK
                LD      (VB_REGISTERS_LOCKED), A

                LD      A, (VB_PAGE_0)
                LD      (old_vb_page_0), A

                LD      HL, 0FFFFh
                CALL    MBB_SET_USR_INT             ; Query the current interrupt...

                LD      A, H
                OR      L

                JR      NZ, uninstall

                CALL    boing_setup
                CALL    install_int

_finished       LD      A, (old_vb_page_0)
                LD      (VB_PAGE_0), A

                LD      A, (lock_status)
                LD      (VB_REGISTERS_LOCKED), A

                LD      A, (old_page_1)
                OUT     (IO_PAGE_1), A

                LD      SP, (old_stack)
                EI
                RET

uninstall       LD      HL, 0                       ; Disable the interrupt call
                CALL    MBB_SET_USR_INT

                XOR     A                           ; And disable the ball layer
                LD      (VB_LAYER_5), A
                JR      _finished

; Relocate boing routine to just below CCP and set the user interrupt to call it
install_int     CALL    MBB_GET_VERSION
                CP      016h
                JR      NZ, _below_ccp

                LD      HL, MBB_SET_USR_INT         ; If we're running BIOS 1.6, we can store ourselves below the jump table
                LD      BC, 5 + UPDATE_LENGTH
                AND     A
                SBC     HL, BC
                JR      _got_location

_below_ccp      LD      HL, (0006h)                 ; BDOS call address
                LD      BC, 0806h + UPDATE_LENGTH
                AND     A
                SBC     HL, BC                      ; HL now points to start of target code space...

_got_location   LD      (res_space), HL
                LD      BC, BOING_OFFSET
                AND     A
                ADC     HL, BC
                LD      (int_addr), HL              ; This is the interrupt address that should be called
                LD      BC, UPDATE_OFFSET
                ADC     HL, BC
                EX      HL, DE                      ; DE is now the update routine that may be called multiple times..

                LD      HL, update_call+1
                LD      (HL), E                     ; Patch the call
                INC     HL
                LD      (HL), D

                LD      DE, (res_space)             ;Copy everything
                LD      HL, RELOC_START
                LD      BC, UPDATE_LENGTH
                LDIR

                LD      HL, (int_addr)         
                CALL    MBB_SET_USR_INT
                RET

res_space       .DW     0
int_addr        .DW     0

;
; Start of the relocatable routine..
;
RELOC_START     

ball_x          .DW     135 * 64
ball_y          .DW     160 * 128
vel_x           .DW     82
vel_y           .DW     0
pal_off         .DB     1               ; Index (-1) of next position to fill red.
layer_base      .DB     0D0h
delay_count     .DB     0
right_edge      .DB     0
top_cell        .DB     0

system_state    .DB     0               ; Old page
                .DB     0               ; Lock status

OLD_PAGE_IDX    .EQU    system_state-boing_ball
LOCK_STATE_IDX  .EQU    system_state-boing_ball+1

BOING_OFFSET    .EQU    $-RELOC_START

boing_ball      PUSH    IX              ; Enter with HL pointing to routine address
                PUSH    HL
                POP     IX

                LD      C, 1                        ; Remember what the current page mappings are so we can restore them later
                CALL    MBB_GET_PAGE
                LD      (IX+OLD_PAGE_IDX), A
                
                LD      A, VIDEOBEAST_PAGE
                OUT     (IO_PAGE_1), A

                LD      A, (VB_REGISTERS_LOCKED)
                LD      (IX+LOCK_STATE_IDX), A

                LD      A, VB_UNLOCK
                LD      (VB_REGISTERS_LOCKED), A

                PUSH    IX
                LD      BC, ball_x-boing_ball
                ADD     IX, BC

update_call     CALL    update_position

                POP     IX

                LD      A, (IX+LOCK_STATE_IDX)
                LD      (VB_REGISTERS_LOCKED), A

                LD      A, (IX+OLD_PAGE_IDX)
                OUT     (IO_PAGE_1), A

                POP     IX
                RET

UPDATE_OFFSET   .EQU    $-boing_ball

                .INCLUDE "boing_update.asm"

UPDATE_LENGTH   .EQU     $-RELOC_START

                .INCLUDE "boing_setup.asm"

stack_space     DEFS    32          ; 16 deep stack..
old_stack       DW      0

old_layer_4     DB      0
old_page_1      DB      0
lock_status     DB      0

old_vb_page_0   DB      0

