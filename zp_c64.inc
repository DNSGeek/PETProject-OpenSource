; ============================================================================
; zp_c64.inc — C64 module scratch map (the historical layout)
;
; These are the exact addresses the modules used as literals before the
; include-file conversion, so a C64 build is byte-for-byte unchanged.
; Do not include this directly — include zp.inc, which selects the target.
;
; Layout:
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
; Why these are free on a C64: $3A-$3F and $F7-$FF belong to BASIC and the
; RS-232 buffers, neither of which is live while a module runs. Note that
; the C64 KERNAL IRQ handler *does* use $FB/$FC as cursor-blink scratch —
; which is why modasm holds sei across an entire assembly (modasm.asm:260).
; That reasoning is C64-specific and must be re-derived for the C128.
; ============================================================================

ZP_SCRATCH      = $3A
ZP_SCRATCH_LEN  = 6

ZP_PTRS         = $F7
ZP_PTRS_LEN     = 8

ZP_OVFLAG       = $FF
