;
;
; Tile page at 192Kb - uses single 16kB page for both tiles and map..
;

 DEVICE ZXSPECTRUM48
 DEFINE tape           boing.tap


VBASE           .EQU    00000h
                .INCLUDE "../common/videobeast.inc"
TILE_PAGE       .EQU    030h                        ; Page 48x4 -> 192K. MUST be a multiple of 8

VB_PORT         .EQU    35
                .ORG    08000h

code_start
                DI
                LD      A, VB_UNLOCK
                LD      (VB_REGISTERS_LOCKED), A

                LD      A, 070h                         ; Read/write ROM, screen writes enabled
                OUT     (VB_PORT), A

                LD      A, (VB_MODE)                    ; Preserve mode, disable Spectrum address mapping
                LD      (old_mode), A
                AND     A, 0Fh
                LD      (VB_MODE), A

                LD      HL, spectrum_layer
                LD      DE, VB_LAYER_4
                LD      BC, 14
                LDIR     

                CALL    boing_setup

boing_loop

_wait_blank     LD      A, (VB_LINE)
                AND     A
                JR      NZ, _wait_blank

                CALL    update_position

_wait_frame     LD      A, (VB_LINE)
                AND     A
                JR      Z, _wait_frame

                LD      BC, 0FBFEh                      ; Read QWERT
                IN      A, (C)
                AND     1
                JR      NZ, boing_loop

                LD      (VB_PAGE_0), A                  ; A is zero, reset page map
                LD      (VB_LAYER_5), A                 ; And hide layer 5

                LD      A, (old_mode)                   ; Restore spectrum screen address decoding
                LD      (VB_MODE), A

                LD      A, 040h                         ; Screen writes only
                OUT     (VB_PORT), A

                EI
                RET

old_mode        .DB     0

                .INCLUDE "boing_update.asm"
                .INCLUDE "boing_setup.asm"

ball_x          .DW     135 * 64
ball_y          .DW     160 * 128
vel_x           .DW     82
vel_y           .DW     0
pal_off         .DB     1               ; Index (-1) of next position to fill red.
layer_base      .DB     0D0h
delay_count     .DB     0
right_edge      .DB     0
top_cell        .DB     0

spectrum_layer  .DB   01h, 03h, 1Ah, 04h, 23h, 00, 00, 00, 00, 10h , 17h, 0Ah, 00, 00


;================================================ END OF CODE =================================
;
code_length     .EQU  $-code_start


 EMPTYTAP tape

 INCLUDE  "../common/zx_loader.asm"

 SAVETAP tape , CODE , "BCode" , code_start , code_length
