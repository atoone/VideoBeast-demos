

; MicroBeast calls
; Call with A -> which bank to map 0-3, and E -> Which physical page to map to 00-1F => ROM, 20-3F => RAM, 40 => VIDEOBEAST
BIOS_SET_PAGE       .EQU   0fde2h  
MICROBEAST_BANK     .EQU   01h
VIDEOBEAST_PAGE     .EQU   40h 

VB_MODE             .EQU   VBASE + 03FFFh
VB_REGISTERS_LOCKED .EQU   VBASE + 03FFEh

VB_BACKGROUND       .EQU   VBASE + 03FFCh	; Word: background colour
VB_LINE             .EQU   VBASE + 03FFAh   ; Word: current screen line

VB_PAGE_0           .EQU   VBASE + 03FF9h
VB_PAGE_1           .EQU   VBASE + 03FF8h
VB_PAGE_2           .EQU   VBASE + 03FF7h
VB_PAGE_3           .EQU   VBASE + 03FF6h

VB_LOWER_REGS       .EQU   VBASE + 03FF5h 	; Byte: Select palette for write


VB_LAYER_0          .EQU   VBASE + 03F80h
VB_LAYER_1          .EQU   VBASE + 03F90h
VB_LAYER_2          .EQU   VBASE + 03FA0h
VB_LAYER_3          .EQU   VBASE + 03FB0h
VB_LAYER_4          .EQU   VBASE + 03FC0h
VB_LAYER_5          .EQU   VBASE + 03FD0h

VB_PALETTE_BASE     .EQU   VBASE + 03F00h

MODE_640            .EQU   0
MODE_848            .EQU   1
MODE_DOUBLE         .EQU   8
MODE_TESTCARD       .EQU   010h

MODE_MAP_16K        .EQU   0
MODE_MAP_SINCLAIR   .EQU   080h

LAYER_TYPE          .EQU   0
LAYER_TOP           .EQU   1
LAYER_BOTTOM        .EQU   2
LAYER_LEFT          .EQU   3
LAYER_RIGHT         .EQU   4
LAYER_SCROLL_X      .EQU   5
LAYER_SCROLL_XY     .EQU   6
LAYER_SCROLL_Y      .EQU   7

TYPE_NONE           .EQU   0
TYPE_TEXT           .EQU   1
TYPE_SPRITE         .EQU   2
TYPE_TILE           .EQU   3
TYPE_BITMAP_8       .EQU   4

TEXT_MAP_BASE       .EQU   8       ; 16Kb character map
TEXT_FONT_BASE      .EQU   9       ;  2Kb font offset
TEXT_PALETTE        .EQU   10      ; Bits 0-3: Palette number   Bit 4: Use Sinclair bit pattern
TEXT_BITMAP         .EQU   11      ; 16Kb 1bpp bitmap..

VB_UNLOCK           .EQU   0F3h           ; Unlock register write

