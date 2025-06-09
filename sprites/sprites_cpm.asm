;
; SPRITE.COM - Sprite Test
;
;


                OUTPUT  "sprites.com"

VBASE           .EQU    04000h

CMD_LEN         .EQU    00080h
CMD_START       .EQU    00081h

IO_PAGE_1       .EQU    071h      ; Page 1: 4000h - 7fffh
PORT_6789       .EQU    0EF00h

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

                LD      E, 0

                LD      A, (CMD_LEN)
                AND     A
                JR      Z, _skip_cmd

                LD      HL, CMD_START
                LD      B, A

_parse_num      LD      A, E
                ADD     A, A
                LD      E, A
                ADD     A, A
                ADD     A, A
                ADD     A, E
                LD      E, A

                LD      A, (HL)
                INC     HL
                CP      ' '
                JR      Z, _next

                SUB     '0'
                JR      C, _skip_cmd
                CP      10
                JR      NC, _skip_cmd
                ADD     E
                LD      E, A
_next           DJNZ    _parse_num

_skip_cmd       LD      A, E
                AND     A
                JR      Z, _run_demo

                LD      (max_sprites), A
_run_demo       CALL    do_sprite_demo

_finished       LD      A, (old_vb_page_0)
                LD      (VB_PAGE_0), A

                LD      A, (lock_status)
                LD      (VB_REGISTERS_LOCKED), A

                LD      A, (old_page_1)
                OUT     (IO_PAGE_1), A

                LD      SP, (old_stack)
                EI
                RET

; Returns with zero flag SET if demo should exit

handle_input    LD      BC, PORT_6789
                IN      A, (C)
                BIT     5, A
                RET

stack_space     DEFS    32          ; 16 deep stack..
old_stack       DW      0

old_page_1      DB      0
lock_status     DB      0

old_vb_page_0   DB      0

                .INCLUDE    "sprites.asm"

