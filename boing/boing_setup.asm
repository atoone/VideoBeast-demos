;
; Boing Setup - routine to set up boing layer
;
; Expects:
;
; VideoBeast to be paged in when boing_setup is called
;
; VBASE and VB_zzzz labels configured for VideoBeast page
;
;

; Videobeast memory map:  (Pages are at 4K offsets)
;      Tiles        @ 160K  (32k free to 256K..) Page 40  (28h) - occupy 4992 bytes (156 tiles @ 32 bytes)
;      Tilemap      @ 160K            *SAME PAGE*               - Free from row 20+  - We'll use row 32, ie. +8192 bytes
;
; Uses palette 11 for ball (avoids Pacman)
; Uses Layer 5 for display (avoids Pacman, clobbers Manic Miner)
;

;
; Bouncing to 512px, ball is 13x8 = 104 px high, so we want to take off 32 px (4*8) to get on screen, plus height of ball = 17 cells.
;
; At top of bounce, ball must be at least 17 cells down... 18 cells = 144px
;


MAP_OFFSET      .EQU    8192                        ; Start of row 32 in the tilemap

boing_setup     LD      A, TILE_PAGE        
                LD      (VB_PAGE_0), A

                ; Expand the tile data into the start of the page

                LD      HL, boing_tiles
                LD      DE, VBASE
                CALL    dzx0_turbo

                ; Then setup the tile map in the second half of the page (we're only displaying a sub-window..)

                LD      HL, VBASE+MAP_OFFSET        ; Clear tilemap
                LD      DE, VBASE+MAP_OFFSET+1
                LD      (HL), 0
                LD      BC, 4096                    ; 16 tile rows
                LDIR

                ; Expand tile map into row 33+, col 1+
                LD      HL, boing_map
                LD      DE, VBASE+MAP_OFFSET+256+2
                LD      C, map_height

_row_loop       LD      B, map_width
_map_loop       LD      A, (HL)
                INC     HL
                LD      (DE), A
                INC     DE
                LD      A, 0B0h                     ; Palette 11, tile enabled
                LD      (DE), A
                INC     DE
                DJNZ    _map_loop

                LD      E, 2
                INC     D
                DEC     C
                JR      NZ, _row_loop

                ; Setup the palette

                LD      A, 2
                LD      (VB_LOWER_REGS), A          ; Palettes 8-12
                LD      DE, VB_PALETTE_BASE+(3*32)  ; We're using palette 11
                LD      HL, palette
                LD      BC, 32
                LDIR

                ; Setup initial parameters
                LD      IX, ball_x
                
                LD      E, START_Y_480
                LD      C, TOP_CELL_480

_edge_ok        LD      A, (VB_MODE)
                AND     MODE_DOUBLE
                JR      Z, _not_double

                LD      C, TOP_CELL_240
                LD      E, START_Y_240

                LD      B, RIGHT_EDGE_424
                LD      A, (VB_MODE)
                AND     1
                JR      NZ, _store_start
                LD      B, RIGHT_EDGE_320
                JR      _store_start

_not_double     LD      B, RIGHT_EDGE_848
                LD      A, (VB_MODE)
                AND     1
                JR      NZ, _store_start
                LD      B, RIGHT_EDGE_640

_store_start    LD      (IX+BALL_Y_IDX+1), E
                LD      (IX+RIGHT_EDGE_IDX), B
                LD      (IX+TOP_CELL_IDX), C

                CALL    update_position

                ; And finally, configure layer 5 to display our ball..
                LD      A, TILE_PAGE/4
                LD      (VB_LAYER_5+8), A
                SRL     A
                LD      (VB_LAYER_5+9), A
                LD      A, TYPE_TILE
                LD      (VB_LAYER_5), A

                RET

                .INCLUDE "../common/zx0_turbo.asm"

palette         .DW     08000h          ; 0: Transparent
                .DW     07000h          ; 1: Red
                .DW     07000h          ; 2
                .DW     07000h          ; 3
                .DW     07000h          ; 4
                .DW     07000h          ; 5
                .DW     07000h          ; 6
                .DW     07000h          ; 7
                .DW     06318h          ; 8 : White
                .DW     06318h          ; 9
                .DW     06318h          ; 10
                .DW     06318h          ; 11
                .DW     06318h          ; 12
                .DW     06318h          ; 13
                .DW     06318h          ; 14

map_width       .EQU   15
map_height      .EQU   13

boing_map       .INCBIN "boing_map.bin"

boing_tiles     .INCBIN "boing_tiles.zx0"
