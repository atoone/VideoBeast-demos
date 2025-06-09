;
; Before including this, use:
;
; DEVICE ZXSPECTRUM48
; DEFINE tape          filename.tap
;
; code_start
;               ... code
; code_length   EQU $-code_start
;
;  EMPTYTAP tape
;  INCLUDE "zx_loader.asm"
;

ZXB_CLEAR       EQU     $FD
ZXB_VAL         EQU     $B0
ZXB_INPUT       EQU     $EE
ZXB_LOAD        EQU     $EF
ZXB_CODE        EQU     $AF
ZXB_RANDOMIZE   EQU     $F9
ZXB_USR         EQU     $C0


            .ORG        05C00h
_bas_start      DB      0, 1                        ; Line number
                DW      _line_len
_line_start     DB      ZXB_CLEAR, ZXB_VAL, '"'
    LUA ALLPASS
      sj.parse_code('DB "' .. tostring(sj.calc("code_start")) .. '"')
    ENDLUA
                DB      '":'
                DB      ZXB_LOAD, '""', ZXB_CODE, ':'
                DB      ZXB_RANDOMIZE, ZXB_USR, ZXB_VAL, '"'
    LUA ALLPASS
      sj.parse_code('DB "' .. tostring(sj.calc("code_start")) .. '"')
    ENDLUA
                DB      '"', 13
_line_len       EQU     $-_line_start
_bas_len        EQU     $-_bas_start                


 SAVETAP tape , BASIC , "Loader" , _bas_start , _bas_len , 1