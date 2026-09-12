; ============================================================================
; layout.inc — per-target memory layout shared by the editor, the module
; loader (modules.asm) and every module source.
;
; The linker configs restate these addresses; the sources assert at link
; time (lderror) that the config they were linked with agrees, so a cfg and
; this file cannot drift apart silently. Assemble with -D TARGET_C128 for
; the C128 map; the default is the historical C64 map.
;
;   EDITOR_LOAD      PRG load address of the editor (start of the BASIC stub)
;   EDITOR_END       exclusive end of the editor's MAIN memory area in the cfg
;   EDITOR_BUF_SIZE  size of the editor's gap-buffer work area
;   MOD_LO_BASE/SIZE the "low" module region: moddet, modtok, moddsk, modren,
;                    modsfr, modscrh load here, and modasm keeps its 4 K of
;                    working state (symbol table etc.) here while it runs
;                    from MOD_HI_BASE. Nothing in this region and nothing in
;                    MOD_HI are ever live at the same time as each other's
;                    peers, so both are shared.
;   MOD_HI_BASE/SIZE the "high" module region: modasm, moddis, modsct, modscr
;
; ---------------------------------------------------------------------------
; C64 (default) — the layout the project has always used
; ---------------------------------------------------------------------------
;   $0801-$8C1E  editor (24 K buffer)          $A000-$BFFF  MOD_HI (8 K)
;   $C000-$CFFF  MOD_LO (4 K)                  $D000+       I/O, KERNAL
;
; ---------------------------------------------------------------------------
; C128 — bank 0, MMU config $0E for the whole session
; ---------------------------------------------------------------------------
; Two things change (see docs/c128-port-notes.md, "Banking"):
;
;   * $C000-$CFFF is the screen-editor ROM, banked as one unit with the
;     KERNAL, so MOD_LO cannot stay there. It moves to $9000-$9FFF.
;   * BASIC 7.0 program text starts at $1C01, not $0801, so the editor loads
;     5 K higher. With MOD_LO at $9000 the editor must end below it, which
;     costs 4.25 K of buffer: EDITOR_BUF_SIZE drops from $6000 to $4F00
;     (19.75 K). The link fails (MAIN overflow) if the editor's BSS grows
;     past $9000; today it ends at $8F1E, leaving 225 bytes.
;
;     The buffer is the price of keeping MOD_HI at $A000 (so modasm, moddis
;     and modsct share their C64 linker configs) and of keeping modasm's
;     symbol table at 400 entries (its state is exactly 4 K). A bank-1
;     buffer (Phase 4 in the notes) gives all of it back and more.
;
;   $1C01-$8F1E  editor (19.75 K buffer)       $A000-$BFFF  MOD_HI (8 K)
;   $9000-$9FFF  MOD_LO (4 K)                  $C000+       ROM, I/O
;
; Not yet done for the C128 (Phase 2 in the notes): the MMU stores that
; replace the $01 banking writes, SETBNK before LOAD/SAVE, the trampolines
; at $033C, and the quit path. This file makes the memory map consistent and
; linkable; it does not make the C128 build bootable.
; ============================================================================

.ifndef LAYOUT_INC_INCLUDED
LAYOUT_INC_INCLUDED = 1

.ifdef TARGET_C128
EDITOR_LOAD     = $1C01
EDITOR_END      = $9000
EDITOR_BUF_SIZE = $4F00
MOD_LO_BASE     = $9000
MOD_LO_SIZE     = $1000
MOD_HI_BASE     = $A000
MOD_HI_SIZE     = $2000
.else
EDITOR_LOAD     = $0801
EDITOR_END      = $D000
EDITOR_BUF_SIZE = $6000
MOD_LO_BASE     = $C000
MOD_LO_SIZE     = $1000
MOD_HI_BASE     = $A000
MOD_HI_SIZE     = $2000
.endif

.assert MOD_LO_BASE + MOD_LO_SIZE <= MOD_HI_BASE || MOD_HI_BASE + MOD_HI_SIZE <= MOD_LO_BASE, error, "layout.inc: MOD_LO and MOD_HI overlap"

.endif ; LAYOUT_INC_INCLUDED
