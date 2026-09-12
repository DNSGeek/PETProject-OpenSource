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
; C128 — the editor in common RAM, the buffer in bank 1, modules in bank 0
; ---------------------------------------------------------------------------
; The MMU selects the RAM bank for all non-common memory at once, so code
; and the data it addresses natively must share a bank. The port splits the
; machine three ways (see docs/c128-port-notes.md, "Bank-1 buffer"):
;
;   * The editor — code and every variable except the buffer, ~9.4 K —
;     loads at $1300 and must end below $4000. With the MMU's RAM
;     configuration register set to a 16 K bottom common area, $0000-$3FFF
;     is the same physical RAM in every bank, so the editor is visible
;     whichever bank is mapped. (The link fails if it grows past $4000.)
;   * The gap buffer is bank 1, $4000-$BFFF: 32 K, all of the bank that is
;     not ROM or I/O. The editor runs with bank 1 mapped (C128_CFG_EDITOR)
;     and addresses it natively, exactly as on the C64.
;   * The modules stay in bank 0 at MOD_LO/MOD_HI and run with bank 0 mapped
;     (C128_CFG_SESSION). They cannot see the buffer directly; every
;     buffer access goes through the far-access helpers the editor keeps
;     in common RAM (FAR_* below, `buf_lda`/`buf_sta` in the modules).
;     The editor switches banks around each module call.
;
;   $1300-$3FFF  editor (bank 0, common)       $4000-$BFFF  bank 1: buffer
;   $9000-$9FFF  bank 0: MOD_LO (4 K)          $A000-$BFFF  bank 0: MOD_HI
;   $C000+       ROM, I/O (both banks)
;
; $1300 rather than BASIC's $1C01 buys the 2.3 K that lets the editor fit
; under $4000; the cost is that BASIC cannot RUN it. The disk's boot sector
; loads it (a reset, or BOOT from BASIC 7.0).
; ============================================================================

.ifndef LAYOUT_INC_INCLUDED
LAYOUT_INC_INCLUDED = 1

.ifdef TARGET_C128
EDITOR_LOAD     = $1300
EDITOR_END      = $4000
EDITOR_BUF_BASE = $4000         ; in bank 1
EDITOR_BUF_SIZE = $8000
MOD_LO_BASE     = $9000
MOD_LO_SIZE     = $1000
MOD_HI_BASE     = $A000
MOD_HI_SIZE     = $2000

; Far-access API: a jump table the editor places right after its entry
; point (see editor.asm `far_api`, asserted at link time). Modules run in
; bank 0 and call these to read or write the bank-1 buffer through the
; pool pointers (ZP_PTR0..3) or the two editor pointers modsfr borrows.
; Each behaves like the instruction it replaces — `lda (ptr),y` sets N/Z
; from the byte, `sta (ptr),y` preserves everything — and clobbers no
; register. Cost is a JSR plus two MMU stores, about 25 cycles.
EDITOR_ENTRY    = EDITOR_LOAD + 12      ; after the 12-byte BASIC stub
FAR_API         = EDITOR_ENTRY + 3      ; first entry, 3 bytes per entry
FAR_LDA_PTR0    = FAR_API + 0 * 3
FAR_STA_PTR0    = FAR_API + 1 * 3
FAR_LDA_PTR1    = FAR_API + 2 * 3
FAR_STA_PTR1    = FAR_API + 3 * 3
FAR_LDA_PTR2    = FAR_API + 4 * 3
FAR_STA_PTR2    = FAR_API + 5 * 3
FAR_LDA_PTR3    = FAR_API + 6 * 3
FAR_STA_PTR3    = FAR_API + 7 * 3
FAR_LDA_TXTPTR  = FAR_API + 8 * 3       ; editor TXT_PTR (modsfr WORK_PTR)
FAR_STA_TXTPTR  = FAR_API + 9 * 3
FAR_LDA_LPTR    = FAR_API + 10 * 3      ; editor LPTR   (modsfr LPTR)
FAR_STA_LPTR    = FAR_API + 11 * 3
FAR_LDA_SCR4    = FAR_API + 12 * 3      ; pool scratch pair ZP_SCRATCH+4/+5 (modren staging copy)
FAR_STA_SCR4    = FAR_API + 13 * 3
FAR_API_ENTRIES = 14
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

; ---------------------------------------------------------------------------
; buf_lda / buf_sta — a module's access to a byte of the editor's buffer
; through a zero-page pointer, `ptr` being one of the pool pointers
; (ZP_PTR0..3) or, for modsfr, the editor's TXT_PTR / LPTR. On the C64 this
; is the plain instruction; on the C128 it is a call into the editor's
; far-access table, because the buffer lives in bank 1 and the module does
; not. Use these ONLY for buffer bytes — a module's own tables and RAM stay
; native `lda (ptr),y`.
; ---------------------------------------------------------------------------
.macro buf_lda ptr
.ifdef TARGET_C128
    .if (ptr) = ZP_PTR0
        jsr FAR_LDA_PTR0
    .elseif (ptr) = ZP_PTR1
        jsr FAR_LDA_PTR1
    .elseif (ptr) = ZP_PTR2
        jsr FAR_LDA_PTR2
    .elseif (ptr) = ZP_PTR3
        jsr FAR_LDA_PTR3
    .elseif (ptr) = ZP_EDITOR + $11
        jsr FAR_LDA_TXTPTR
    .elseif (ptr) = ZP_EDITOR + $13
        jsr FAR_LDA_LPTR
    .elseif (ptr) = ZP_SCRATCH + 4
        jsr FAR_LDA_SCR4
    .else
        .error "buf_lda: no far-access helper for this pointer"
    .endif
.else
    lda (ptr),y
.endif
.endmacro

.macro buf_sta ptr
.ifdef TARGET_C128
    .if (ptr) = ZP_PTR0
        jsr FAR_STA_PTR0
    .elseif (ptr) = ZP_PTR1
        jsr FAR_STA_PTR1
    .elseif (ptr) = ZP_PTR2
        jsr FAR_STA_PTR2
    .elseif (ptr) = ZP_PTR3
        jsr FAR_STA_PTR3
    .elseif (ptr) = ZP_EDITOR + $11
        jsr FAR_STA_TXTPTR
    .elseif (ptr) = ZP_EDITOR + $13
        jsr FAR_STA_LPTR
    .elseif (ptr) = ZP_SCRATCH + 4
        jsr FAR_STA_SCR4
    .else
        .error "buf_sta: no far-access helper for this pointer"
    .endif
.else
    sta (ptr),y
.endif
.endmacro

.endif ; LAYOUT_INC_INCLUDED
