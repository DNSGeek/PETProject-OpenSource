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
C128_CFG_SESSION    = $0E   ; bank 0: RAM $0002-$BFFF, I/O at $D000, KERNAL ROM above
C128_CFG_EDITOR     = $4E   ; same map over bank 1 — the editor's session config
C128_CFG_BASIC      = $00   ; BASIC 7.0's "bank 15": BASIC + KERNAL ROM, I/O

; Preconfiguration registers: $D501-$D504 hold four configs; a write of ANY
; value to the mirror $FF01-$FF04 loads the matching one into the CR without
; disturbing A. The editor sets A = C128_CFG_EDITOR (bank 1) and
; B = C128_CFG_SESSION (bank 0), so a bank switch is a single `sta` with no
; register to spare — which is what makes the far-access helpers cheap.
; The KERNAL never writes these (checked in the 318020-05 image); the
; originals are saved at startup and restored on quit for BASIC's sake.
C128_MMU_PCR_A      = $D501
C128_MMU_PCR_B      = $D502
C128_MMU_LOAD_A     = $FF01 ; write anything: CR := PCR A (bank 1, editor)
C128_MMU_LOAD_B     = $FF02 ; write anything: CR := PCR B (bank 0, modules)

; RAM configuration register: bits 0-1 = size of the bottom common area
; (00 1 K, 01 4 K, 10 8 K, 11 16 K), bit 2 = bottom common enabled, bit 3 =
; top common enabled, bits 6-7 = VIC RAM bank. The editor needs 16 K bottom
; common so that $0000-$3FFF — its own code and variables, the screen, and
; everything the KERNAL touches — is the same memory in bank 0 and bank 1.
; The screen editor ROM rewrites this register only to change bits 6-7 and
; puts the original back (disassembled at $CF80), so the setting survives.
C128_MMU_RCR        = $D506
C128_RCR_COMMON16K  = $07   ; bits 0-2: 16 K, bottom common on
C128_RCR_COMMON_MASK = $F8  ; bits we leave alone when setting the above

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
; 2 MHz
; ---------------------------------------------------------------------------
; VIC-IIe clock-rate register: bit 0 set = 2 MHz. The 40-column VIC cannot
; fetch at 2 MHz, so the display is blanked (VIC control register 1, bit 4
; clear) for the duration — the "blank-screen burst" of the port notes. The
; KERNAL's jiffy IRQ is raster-driven and keeps running. Only used around
; module calls that do no KERNAL I/O (serial timing is CIA-driven and would
; break) and show nothing the user needs to see.
C128_VIC_CLKRATE    = $D030
C128_VIC_CTRL1      = $D011
C128_VIC_DEN        = $10   ; display enable bit in C128_VIC_CTRL1

; ---------------------------------------------------------------------------
; BASIC 7.0
; ---------------------------------------------------------------------------
C128_BASIC_COLD     = $4000 ; JMP cold start; needs C128_CFG_BASIC in the MMU

; ---------------------------------------------------------------------------
; Boot-sector handshake (boot128.asm)
; ---------------------------------------------------------------------------
; BASIC's cold start ends by calling the KERNAL boot routine, which runs the
; disk's boot sector — so quitting the editor via BASIC_COLD on an autoboot
; disk would relaunch it. The quit path leaves this marker; the boot sector
; sees it, clears it and returns to BASIC instead of loading the editor.
; $0FFF is the last byte of the sprite-definition area ($0E00-$0FFF), which
; nothing in the session uses: untouched by BASIC's init, by the boot loader
; ($0B00 sector buffer) and by the editor's own load ($1300 up). A power
; cycle randomises it, a reset does not — which is why the boot sector
; clears it, so the next reset boots normally.
C128_BOOT_FLAG      = $0FFF
C128_BOOT_FLAG_QUIT = $51   ; 'Q'
