; ============================================================================
; zp.inc — zero-page scratch pool for PETProject loadable modules
;
; Include this at the top of every module that uses zero-page scratch.
; Selects the per-target map; assemble with `-D TARGET_C128` for the C128.
;
; ---------------------------------------------------------------------------
; WHAT THIS COVERS
; ---------------------------------------------------------------------------
; The *module* scratch tier only. Two other tiers exist and are NOT defined
; here:
;
;   1. The editor's own block, declared as a `.zeropage` segment in
;      editor.asm and placed by the `ZP:` entry in petproject.cfg. It is
;      already relocatable by changing one line in the linker config.
;
;   2. BASIC and KERNAL ABI addresses — TXTTAB ($2B), VARTAB ($2D),
;      MEMSIZ ($37), VARPNT ($47), TXTPTR ($7A), AYINT's output ($14/$15),
;      JIFFY_LO ($A2), FA ($BA). These are *not ours to relocate*; they are
;      fixed by the ROM we are calling. They stay as literals at their use
;      sites in modscr.asm / modscrh.asm / editor.asm / moddsk.asm.
;
; See docs/c128-port-notes.md for the full audit.
;
; ---------------------------------------------------------------------------
; CONTRACT — any target map must satisfy all of these
; ---------------------------------------------------------------------------
;   ZP_SCRATCH   6 CONTIGUOUS bytes. Modules address it as ZP_SCRATCH+0..+5
;                and index it (`lda ZP_SCRATCH,x`) in save/restore loops.
;                Sub-slots are used as 16-bit values, so +0/+1, +2/+3 and
;                +4/+5 must each be an adjacent pair.
;
;   ZP_PTRS      8 CONTIGUOUS bytes = four 2-byte pointers at +0, +2, +4, +6.
;                Every one of these is dereferenced with (zp),y, so each pair
;                must be adjacent and must not straddle the end of page zero.
;
;   ZP_OVFLAG    1 byte. Standalone flag; no adjacency requirement.
;
;   All 15 bytes must be disjoint from the editor's `.zeropage` block, and
;   disjoint from anything the target KERNAL touches — including its IRQ
;   handler, which runs throughout (the editor issues no sei/cli of its own).
; ============================================================================

.ifdef TARGET_C128
    .include "zp_c128.inc"
.else
    .include "zp_c64.inc"
.endif

; ---------------------------------------------------------------------------
; Derived pointer slots — same on every target, computed from ZP_PTRS.
; ---------------------------------------------------------------------------
ZP_PTR0         = ZP_PTRS + 0
ZP_PTR1         = ZP_PTRS + 2
ZP_PTR2         = ZP_PTRS + 4
ZP_PTR3         = ZP_PTRS + 6

; ---------------------------------------------------------------------------
; Contract assertions — a bad target map fails the build.
;
; ca65 evaluates .assert at the END of assembly and skips it if the assembly
; already produced errors. So a map whose ADDRESSES are out of page zero
; usually surfaces first as "Range error (256 not in [0..255])" at the use
; site, and these messages never print. That is fine — the build still fails
; — but don't expect the friendly message in that case. A map that is merely
; the wrong SHAPE (bad length) does report through here.
; ---------------------------------------------------------------------------
.assert ZP_SCRATCH >= 2 && ZP_SCRATCH + ZP_SCRATCH_LEN <= $100, error, "zp.inc: ZP_SCRATCH block does not fit in page zero"
.assert ZP_PTRS >= 2 && ZP_PTRS + ZP_PTRS_LEN <= $100, error, "zp.inc: ZP_PTRS block does not fit in page zero"
.assert ZP_OVFLAG >= 2 && ZP_OVFLAG <= $FF, error, "zp.inc: ZP_OVFLAG is not in page zero"
.assert ZP_SCRATCH_LEN = 6, error, "zp.inc: ZP_SCRATCH must be 6 bytes"
.assert ZP_PTRS_LEN = 8, error, "zp.inc: ZP_PTRS must be 8 bytes"
