;
; Main Sprite routine, includes setup and animation
; 
; Expects:
;
; VideoBeast to be paged in when do_sprite_demo is called
;
; Expects the following labels defined:
;    VBASE and VB_zzzz labels configured for VideoBeast page
;
; Addresses 08000h -> 0C800h to be free to write

; Uses ../assets/cozy.dat - Generated with:
; > tiler -s 2 2 -g -i cozy.png -o cozy.dat -w cozy.pal cozy_16x16.png
;
; Total of 144 2x2 sprites (576 cells), 18432 bytes - single palette
;
; Compressed to cozy.dat.zx0 - 5286 bytes
;
;    Sprite list 1    @ 40k                        Page 10
;    Sprite list 2    @ 42K
;
; Sprite cells        @ 160K  (32k free to 256K..) Page 40  (28h) - occupy 18432 bytes (576 cells @ 32 bytes)
;
; Uses Palette 10
;      Layer   5
;
;

SPRITE_CELL_PAGE    .EQU    28h
SPRITE_MAP_PAGE     .EQU    0Ah

MAP_1               .EQU    SPRITE_MAP_PAGE * 2         ; Base of page, in 2kb chunks

FREE_MEM            .EQU    08000h

                    ; Expand sprite data (around 18Kb) into free memory
do_sprite_demo      LD      HL, sprite_cells
                    LD      DE, FREE_MEM
                    CALL    dzx0_turbo

                    LD      A, SPRITE_CELL_PAGE   
                    LD      HL, FREE_MEM

                    ; Copy five 4k blocks into video RAM
_cell_copy          LD      (VB_PAGE_0), A
                    LD      BC, 4096
                    LD      DE, VBASE
                    LDIR

                    INC     A
                    CP      SPRITE_CELL_PAGE+5
                    JR      NZ, _cell_copy

                    LD      A, 2
                    LD      (VB_LOWER_REGS), A          ; Palettes 8-12
                    LD      DE, VB_PALETTE_BASE+(2*32)  ; We're using palette 10
                    LD      HL, palette
                    LD      BC, 32
                    LDIR

                    LD      HL, layer_default           ; Just set up layer bounds, layer is disabled
                    LD      DE, VB_LAYER_5
                    LD      BC, 12
                    LDIR 

                    LD      A, (VB_MODE)
                    AND     MODE_DOUBLE
                    JR      Z, draw_map

                    LD      DE, 03500h
                    LD      (screen_x), DE
                    LD      DE, 07800h
                    LD      (screen_y), DE
                    LD      DE, 0
                    LD      (velocity_adj), DE

draw_map            CALL    handle_input
                    RET     Z

                    LD      A, SPRITE_MAP_PAGE
                    LD      (VB_PAGE_0), A

                    LD      DE, VBASE
                    LD      A, (sprite_map)
                    CP      MAP_1
                    JR      Z, _is_map_1

                    LD      DE, VBASE + 2048
_is_map_1  
                    LD      (map_stack), SP
                    LD      SP, sprite_blocks
                    LD      BC, 0FFh

                    XOR     A
                    LD      (sprite_count), A

                    ; At this point:
                    ;     B is the current sprite index (in sprite block), 
                    ;     C is the first free sprite index
                    ;     DE is the target sprite map, 
                    ;     SP is the source sprite blocks

_map_loop           LD      A, (sprite_block_count)
                    CP      B
                    JR      Z, _map_complete
                    LD      (map_bc), bc

                    POP     HL              ; First two bytes of sprite defn. Palette and cell index
                    LD      A, H
                    OR      L
                    JR      Z, _skip_sprite

                    EX      DE, HL
                    LD      (HL), E
                    INC     HL 
                    LD      (HL), D
                    INC     HL
                    EX      DE, HL

                    POP     BC              ; X velocity
                    POP     HL              ; X position
                    ADD     HL, BC
                    PUSH    HL

                    EX      DE, HL          ; DE is now 10.6 x position

                    LD      A, 004h         ; Width is 2 cells - bit gets rotated left twice into position

                    SLA     E
                    RL      D
                    RL      A

                    SLA     E
                    RL      D
                    RL      A

                    LD      (HL), D
                    INC     HL
                    LD      (HL), A
                    INC     HL
                    EX      DE, HL

                    POP     BC              ; Discard X position..

                    POP     HL              ; Y velocity
                    LD      BC, 16          ; gravity
                    ADD     HL, BC
                    PUSH    HL

                    POP     BC              ; Updated Y velocity
                    POP     HL              ; Y position
                    ADD     HL, BC
                    
                    PUSH    HL              ; Store it
                    POP     HL
                    JR      NC, _y_is_ok

                    RLC     B
                    JR      C, _y_is_ok 

                    ; BC is positive, Y position has carried over - kill sprite.

                    DEC     DE              ; Easiest way to go back to beginning...
                    DEC     DE
                    DEC     DE
                    DEC     DE

_next_sprite        LD      HL, -10
                    ADD     HL, SP
                    LD      (HL), 0
                    INC     HL
                    LD      (HL), 0

                    LD      BC, (map_bc)     ; First free index..
                    LD      A, C
                    INC     A
                    JR      NZ, _already_found
                    LD      C, B
_already_found      INC     B
                    JR      _map_loop

_y_is_ok            EX      DE, HL          ; DE is now 9.7 y position

                    LD      A, 048h         ; Sprite enable, height 2 cells - gets rotated into position
                    SLA     E
                    RL      D
                    RL      A

                    LD      (HL), D
                    INC     HL
                    LD      (HL), A
                    INC     HL
                    EX      DE, HL
                    
                    INC     DE
                    INC     DE

                    LD      HL, sprite_count        ; Count this sprite..
                    INC     (HL)

                    LD      BC, (map_bc)
                    INC     B
                    JR      _map_loop

_skip_sprite        POP     HL
                    POP     HL
                    POP     HL
                    POP     HL
                    JR      _next_sprite

_map_complete       LD      SP, (map_stack)

                    ; Wait for sync period..
_wait_line          LD      A, (VB_LINE)
                    AND     A
                    JR      NZ, _wait_line

                    LD      A, (sprite_map)
                    LD      (VB_LAYER_5+8), A       ; Set sprite map base
                    XOR     1
                    LD      (sprite_map), A         ; Flip to other map for next round

                    LD      A, (sprite_count)
                    LD      (VB_LAYER_5+10), A      ; Set number of sprites

                    AND     A
                    JR      Z, _set_layer
                    LD      A, TYPE_SPRITE
_set_layer          LD      (VB_LAYER_5), A         ; (Dis)enable sprite layer

_wait_frame         LD      A, (VB_LINE)            ; Now wait for start of frame..
                    AND     A
                    JR      Z, _wait_frame

                    ; Add sprite if we're below max...
                    LD      A, (sprite_count)
                    LD      B, A
                    LD      A, (max_sprites)
                    CP      B
                    JR      NZ, add_sprite
                    JP      draw_map

add_sprite          LD      A, C
                    INC     A
                    JR      NZ, _got_index
                    
                    LD      HL, sprite_block_count   ; We haven't got a free sprite block so allocate the next one..
                    LD      C, (HL)
                    INC     (HL)

_got_index          LD      H, 0
                    LD      L, C
                    ADD     HL, HL
                    LD      B, H
                    LD      C, L
                    ADD     HL, HL
                    ADD     HL, HL
                    ADD     HL, BC
                    LD      BC, sprite_blocks
                    ADD     HL, BC

                    ; HL now points to a free sprite block
                    EX      DE, HL
_pick_graphic       CALL    prng16                  ; Choose a sprite
                    LD      A, L      
                    CP      UNIQUE_GRAPHICS
                    JR      NC, _pick_graphic

                    LD      L, A
                    LD      H, 050h
                    ADD     HL, HL

                    EX      DE, HL
                    LD      (HL), E
                    INC     HL
                    LD      (HL), D
                    INC     HL

                    EX      DE, HL
                    CALL    prng16                  ; X velocity
                    LD      H, 0
                    BIT     7, L
                    JR      Z, _x_positive
                    LD      H, 0FFh
_x_positive         EX      DE, HL
                    LD      (HL), E
                    INC     HL
                    LD      (HL), D
                    INC     HL

                    LD      DE, (screen_x)              ; 424 pixels in 10.6 fixed point
                    LD      (HL), E
                    INC     HL
                    LD      (HL), D
                    INC     HL

                    EX      DE, HL
                    CALL    prng16                  ; Y velocity (9.7)

                    LD      A, 0FCh
                    OR      H
                    LD      H, A
                    LD      BC, (velocity_adj)
                    ADD     HL, BC

                    EX      DE, HL
                    LD      (HL),E
                    INC     HL
                    LD      (HL), D
                    INC     HL

                    LD      DE, (screen_y)              ; 480 pixels in 9.7
                    LD      (HL), E
                    INC     HL
                    LD      (HL), D

                    JP      draw_map

; Random number generator from: https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Random
;Inputs:
;   (seed1) contains a 16-bit seed value
;   (seed2) contains a NON-ZERO 16-bit seed value
;Outputs:
;   HL is the result
;   BC is the result of the LCG, so not that great of quality
;   DE is preserved
;Destroys:
;   AF
;cycle: 4,294,901,760 (almost 4.3 billion)
;160cc
;26 bytes
prng16              LD      HL,(rng_seed1)
                    LD      B,H
                    LD      C,L
                    ADD     HL,HL
                    ADD     HL,HL
                    INC     L
                    ADD     HL,BC
                    LD      (rng_seed1),HL
                    LD      HL,(rng_seed2)
                    ADD     HL,HL
                    SBC     A,A
                    AND     00101101b
                    XOR     L
                    LD      L,A
                    LD      (rng_seed2),HL
                    ADD     HL,BC
                    RET

rng_seed1           .DW     0C938h
rng_seed2           .DW     012F3h


UNIQUE_GRAPHICS     .EQU    144

sprite_block_count  .DB     0           ; Number of blocks in use
sprite_count        .DB     0           ; Number of active sprites
max_sprites         .DB     1

screen_x            .DW     06A00h
screen_y            .DW     0F000h
velocity_adj        .DW     -080h

map_stack           .DW     0           ; Storage for registers during map loop
map_bc              .DW     0

sprite_map          .DB     MAP_1        ; 2K base page for sprite map


free_sprite         .DW     0           ; Address of next free sprite..

palette             .DW     08000h  ; Transparent
                    .DW     02108h  ; 1: 0x393938
                    .DW     02198h  ; 2: 0x3a66cf
                    .DW     02284h  ; 3: 0x3ca42a
                    .DW     0229ch  ; 4: 0x53acf4
                    .DW     04194h  ; 5: 0xa25dc6
                    .DW     0531ch  ; 6: 0xa6e4fe
                    .DW     05290h  ; 7: 0xaba4a0
                    .DW     05104h  ; 8: 0xb9522f
                    .DW     0529ch  ; 9: 0xc7afee
                    .DW     06294h  ; 10: 0xd3b4af
                    .DW     06288h  ; 11: 0xe2b350
                    .DW     07310h  ; 12: 0xfce0a1
                    .DW     0739ch  ; 13: 0xfdfdfd
                    .DW     07304h  ; 14: 0xffe11d


layer_default       .DB     0                           ; 0 : Disable layer initially
                    .DB     0, 59                       ; 1 : Top, bottom (0-479)
                    .DB     0, 105                      ; 3 : Left right  (0-847)
                    .DB     0,0,0                       ; 5 : No scroll
                    .DB     0                           ; 8 : Sprite map base * 2k
                    .DB     SPRITE_CELL_PAGE / 8        ; 9 : Sprite cell base * 32Kb
                    .DB     0                           ; 10: Sprite count

; Sprite block - 10 bytes
;
; Word: Sprite palette and index
; Word: X velocity
; Word: X pos               ; 10.6 fixed point
; Word: Y velocity
; Word: Y pos               ; 9.7 fixed point
;
                .INCLUDE "../common/zx0_turbo.asm"

sprite_cells
                .INCBIN  "../assets/cozy.dat.zx0"

sprite_blocks   ; Area for sprite blocks. Technically we could overwrite the sprite cell data, but.. meh
