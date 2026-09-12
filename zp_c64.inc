; ============================================================================
; zp_c64.inc — C64 module scratch map (the historical layout)
;
; These are the exact addresses the modules used as literals before the
; include-file conversion, so a C64 build is byte-for-byte unchanged.
; Do not include this directly — include zp.inc, which selects the target.
;
; Layout:
;   $02-$1B   ZP_EDITOR    the editor's .zeropage block (petproject.cfg)
;   $3A-$3F   ZP_SCRATCH   general scratch (TMP/TMP2/TMP3, LINENO, KW_TOKEN,
;                          KW_XSAVE, TMP16, NZFLAG, KWTAB, IN_STRING,
;                          AFTER_REM, OVFLAG, HND_TMP — names vary by module)
;   $F7-$FE   ZP_PTRS      four pointer pairs
;                            +0 = $F7  COPY_SRC / LINK_PTR
;                            +2 = $F9  COPY_DST / BASIC_ADDR
;                            +4 = $FB  SRC_PTR  / DSK_PTR
;                            +6 = $FD  DST_PTR  / DSK_PTR2
;   $FF       ZP_OVFLAG    staging overflow flag (modtok, modsct)
;
; Why these are free on a C64: $3A-$3F belongs to BASIC and $F7-$FA to the
; RS-232 buffer pointers, neither of which is live while a module runs;
; $FB-$FE are the C64's documented free-for-user zero-page bytes. The C64
; KERNAL IRQ handler does NOT touch any of them — its cursor blink and
; keyboard scan use $A0-$A2, $C5/$C6/$CB, $CC-$CF, $D1-$D6 and $F3-$F6.
; (moddet, modtok and moddsk run with IRQs enabled on these addresses.)
; modasm and moddis still hold sei across their run as a precaution; that is
; not a requirement of this layout.
; ============================================================================

ZP_EDITOR       = $02   ; must match petproject.cfg  ZP: start
ZP_EDITOR_LEN   = $1A   ; must match petproject.cfg  ZP: size

ZP_SCRATCH      = $3A
ZP_PTRS         = $F7
ZP_OVFLAG       = $FF
