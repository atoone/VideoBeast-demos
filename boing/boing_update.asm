;
;
; Boing update - relocatable code to update the boing ball position
;

;
; Store Y position as 9.7 fixed point, X position as 10.6
;
; Y is positive down the screen (ie. 0 at top)
;

BALL_X_IDX      .EQU    0
BALL_Y_IDX      .EQU    2
VEL_X_IDX       .EQU    4
VEL_Y_IDX       .EQU    6
PAL_IDX         .EQU    8
LAYER_BASE_IDX  .EQU    9
DELAY_IDX       .EQU    10
RIGHT_EDGE_IDX  .EQU    11
TOP_CELL_IDX    .EQU    12

START_Y_240     .EQU    200
START_Y_480     .EQU    80

TOP_CELL_240    .EQU    ((512-240)+104)/8
TOP_CELL_480    .EQU    ((512-480)+104)/8       ; 17

RIGHT_EDGE_320  .EQU    (320-120)/4            
RIGHT_EDGE_424  .EQU    (424-120)/4 
RIGHT_EDGE_640  .EQU    (640-120)/4              
RIGHT_EDGE_848  .EQU    (848-120)/4             ; 182            

;
; Assuming IX is pointing to base of ball parameters, update the position and write it to the layer and palette registers
;
update_position LD      D, VB_PALETTE_BASE >> 8
                LD      E, (IX+LAYER_BASE_IDX)
                INC     DE

                LD      C, (IX+VEL_Y_IDX)
                LD      B, (IX+VEL_Y_IDX+1)
                LD      L, (IX+BALL_Y_IDX)
                LD      H, (IX+BALL_Y_IDX+1)
                AND     A
                ADC     HL, BC
                JR      NC, _no_bounce
                BIT     7, B
                JR      NZ, _no_bounce          ; Inverted for negative velocity

                XOR     A                       ; Negate BC (Velocity)
                SUB     C
                LD      C,A
                SBC     A,A
                SUB     B
                LD      B,A
                
                XOR     A                       ; Negate HL (Position)
                SUB     L
                LD      L,A
                SBC     A,A
                SUB     H
                LD      H,A

_no_bounce      PUSH    HL                      ; Do gravity
                LD      HL, 16
                XOR     A
                ADC     HL, BC
                LD      (IX+VEL_Y_IDX), L
                LD      (IX+VEL_Y_IDX+1), H

                POP     HL

                LD      (IX+BALL_Y_IDX), L
                LD      (IX+BALL_Y_IDX+1), H
                LD      A, L
                SRL     H
                RR      A
                SRL     H
                RR      A
                AND     0E0h                    ; Top three bits = position within cell
                JR      Z, _exact_cell_y
                INC     H
_exact_cell_y   LD      L, A                    ; Store cell Y position in L
                LD      A, H
                SUB     (IX+TOP_CELL_IDX)       ; Shift up 17 cells -> so 512 limit is 480 pixels - height of ball..
                JR      NC, _top_ok
                XOR     A
_top_ok         LD      (DE), A
                INC     DE
                ADD     A, map_height
                LD      (DE), A
                INC     DE

                PUSH    HL

                LD      C, (IX+VEL_X_IDX)
                LD      B, (IX+VEL_X_IDX+1)
                LD      L, (IX+BALL_X_IDX)
                LD      H, (IX+BALL_X_IDX+1)
                AND     A
                ADC     HL, BC

                LD      A, H
                CP      (IX+RIGHT_EDGE_IDX)     ; Check against right edge
                JR      C, _x_vel_ok

                XOR     A                       ; Negate BC (Velocity)
                SUB     C
                LD      C,A
                SBC     A,A
                SUB     B
                LD      B,A
                LD      (IX+VEL_X_IDX), C
                LD      (IX+VEL_X_IDX+1), B

                AND     A
                ADC     HL, BC

_x_vel_ok       LD      (IX+BALL_X_IDX), L
                LD      (IX+BALL_X_IDX+1), H

                LD      A, L
                SRL     H
                RR      A
                AND     0E0h                    ; Top three bits - position within cell
                JR      Z, _exact_cell_x
                INC     H
_exact_cell_x   LD      C, A                    ; Cell X position in C
                LD      A, H
                LD      (DE), A
                INC     DE
                ADD     A, map_width
                LD      (DE), A
                INC     DE
                POP     HL                      ; Cell Y position in L

                ; Now convert cell position to scroll offset...
                LD      A, C
                RLC     A
                RLC     A
                RLC     A
                JR      Z, _scroll_x_ok

                XOR     7
                INC     A
_scroll_x_ok    LD      (DE),A
                INC     DE
                LD      A, 010h                 ; +256 pixels Y to show from row 32
                LD      (DE), A
                INC     DE
                LD      A, L
                RLC     A
                RLC     A
                RLC     A
                JR      Z, _scroll_y_ok

                XOR     7
                INC     A
_scroll_y_ok    LD      (DE), A

                LD      A, (IX+DELAY_IDX)
                INC     (IX+DELAY_IDX)
                AND     1
                RET     Z

                ; Finally, update palette

                LD      A, (VB_LOWER_REGS)
                LD      E, A

                LD      A, 2
                LD      (VB_LOWER_REGS), A          ; Palettes 8-12
                LD      BC, VB_PALETTE_BASE+(3*32)  ; We're using palette 11


                LD      A, (IX+PAL_IDX)
                DEC     A
                JR      NZ, _pal1_ok
                LD      A, 14
_pal1_ok        LD      (IX+PAL_IDX), A

                LD      H, 0
                LD      L, A
                SLA     L
                ADD     HL, BC
                LD      (HL), 00h
                INC     HL
                LD      (HL), 070h

                SUB     7
                JR      Z, _pal_wrap
                JR      C, _pal_wrap
                
_pal2_ok        LD      H, 0
                LD      L, A
                SLA     L
                ADD     HL, BC

                LD      (HL), 018h
                INC     HL
                LD      (HL), 063h

                LD      A, E
                LD      (VB_LOWER_REGS), A
                RET

_pal_wrap       ADD     14
                JR      _pal2_ok