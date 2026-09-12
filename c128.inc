; ============================================================================
; c128.inc — C128 hardware and KERNAL constants used by the port.
;
; Included only under -D TARGET_C128. Everything here is fixed by the C128
; ROMs and MMU; none of it is ours to relocate (compare zp.inc's note on the
; BASIC/KERNAL zero-page ABI). Source: C128 Programmer's Reference Guide and
; the CBM archive's C128 RAM map; the KERNAL jump-table entries and the
; $0A22 / $1000 references were checked against the 318020-05 KERNAL image.
;
; ---------------------------------------------------------------------------
; MMU
; ---------------------------------------------------------------------------
; $FF00 mirrors the configuration register at $D500 and is visible from
; every bank, so a single store switches the map from anywhere.
;   bit 0    $D000-$DFFF   0 = I/O, 1 = ROM/RAM per bits 4-5
;   bit 1    $4000-$7FFF   0 = BASIC LO ROM, 1 = RAM
;   bits 2-3 $8000-$BFFF   00 = BASIC HI ROM, 11 = RAM
;   bits 4-5 $C000-$FFFF   00 = screen-editor + KERNAL ROM, 11 = RAM
;   bits 6-7 RAM bank      00 = bank 0
; PETProject runs the whole session in $0E: RAM from $0002 to $BFFF, I/O,
; KERNAL ROM. That is the map layout.inc assumes — see the "$C000
; collision" section of docs/c128-port-notes.md for why $C000-$CFFF cannot
; hold code and why MOD_LO moved to $9000.
C128_MMU_CR         = $FF00
C128_CFG_SESSION    = $0E   ; RAM $0002-$BFFF, I/O at $D000, KERNAL ROM above
C128_CFG_BASIC      = $00   ; BASIC 7.0's "bank 15": BASIC + KERNAL ROM, I/O

; ---------------------------------------------------------------------------
; KERNAL entries the port adds (C64 code needs none of these)
; ---------------------------------------------------------------------------
C128_SWAPPER        = $FF5F ; toggle between the 40- and 80-column screens
C128_SETBNK         = $FF68 ; A = bank for LOAD/SAVE data, X = bank of filename

; ---------------------------------------------------------------------------
; KERNAL variables that moved or are new relative to the C64
; ---------------------------------------------------------------------------
C128_MODE           = $D7   ; bit 7 set = 80-column (VDC) screen is active
C128_KEYRPT         = $0A22 ; key-repeat flag, same encoding as C64 $028A:
                            ;   $80 = all keys repeat, $40 = none, $00 = default
; F1-F8, SHIFT-RUN and HELP are programmable keys: the screen editor expands
; them into these strings before GETIN sees anything. PKYLEN holds the ten
; string lengths, PKYDEF the strings packed back to back.
C128_PKYLEN         = $1000
C128_PKYDEF         = $100A

; ---------------------------------------------------------------------------
; BASIC 7.0
; ---------------------------------------------------------------------------
C128_BASIC_COLD     = $4000 ; JMP cold start; needs C128_CFG_BASIC in the MMU
