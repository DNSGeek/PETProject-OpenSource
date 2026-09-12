; ============================================================================
; zp.inc — zero-page scratch pool for PETProject loadable modules
;
; Include this at the top of every module that uses zero-page scratch.
; Selects the per-target map; assemble with `-D TARGET_C128` for the C128.
; Guarded, so a translation unit may include it more than once.
;
; ---------------------------------------------------------------------------
; WHAT THIS COVERS
; ---------------------------------------------------------------------------
; The *module* scratch tier (Tier 2), plus the base/size of the editor's
; block (Tier 1) so the two can be checked against each other. Two other
; things are NOT defined here:
;
;   1. The editor's own block contents, declared as a `.zeropage` segment in
;      editor.asm and placed by the `ZP:` entry in petproject.cfg. That cfg
;      line must agree with ZP_EDITOR / ZP_EDITOR_LEN below; editor.asm
;      asserts the agreement at link time (lderror). modsfr.asm borrows six
;      of those bytes by offset from ZP_EDITOR, and editor.asm pins those
;      offsets at link time too — so relocating Tier 1 means changing the
;      target map AND petproject.cfg together, and the build fails if only
;      one moves.
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
;   ZP_EDITOR    Base of the editor's `.zeropage` block; ZP_EDITOR_LEN its
;                size. Must equal petproject.cfg's `ZP: start/size`.
;
;   ZP_SCRATCH   6 CONTIGUOUS bytes. Modules address it as ZP_SCRATCH+0..+5
;                and index it (`lda ZP_SCRATCH,x`) in save/restore loops.
;                Sub-slots are used as 16-bit values at various offsets
;                (+0/+1, +2/+3, +3/+4, +4/+5 depending on module), so the
;                block must be one contiguous run inside page zero.
;
;   ZP_PTRS      8 CONTIGUOUS bytes = four 2-byte pointers at +0, +2, +4, +6.
;                Every one of these is dereferenced with (zp),y, so each pair
;                must be adjacent and must not straddle the end of page zero.
;
;   ZP_OVFLAG    1 byte. Standalone flag; no adjacency requirement.
;
;   All 15 pool bytes must be disjoint from each other and from the editor
;   block (asserted below), and disjoint from anything the target KERNAL
;   touches — including its IRQ handler, which runs throughout (the editor
;   issues no sei/cli of its own).
; ============================================================================

.ifndef ZP_INC_INCLUDED
ZP_INC_INCLUDED = 1

.ifdef TARGET_C128
    .include "zp_c128.inc"
.else
    .include "zp_c64.inc"
.endif

; Block lengths are part of the contract, not per-target knobs.
ZP_SCRATCH_LEN  = 6
ZP_PTRS_LEN     = 8

; ---------------------------------------------------------------------------
; Derived pointer slots — same on every target, computed from ZP_PTRS.
; ---------------------------------------------------------------------------
ZP_PTR0         = ZP_PTRS + 0
ZP_PTR1         = ZP_PTRS + 2
ZP_PTR2         = ZP_PTRS + 4
ZP_PTR3         = ZP_PTRS + 6

; Size of a module's ZP save area: the scratch block plus ZP_PTR2/ZP_PTR3.
ZP_SAVE_LEN     = ZP_SCRATCH_LEN + 4

; ---------------------------------------------------------------------------
; Contract assertions — a bad target map fails the build.
;
; ca65 evaluates .assert at the END of assembly and skips it if the assembly
; already produced errors, so an out-of-page address usually surfaces first
; as a "Range error" at a use site. Overlaps between blocks produce no range
; error, which is why they are asserted explicitly here.
; ---------------------------------------------------------------------------
.assert ZP_SCRATCH + ZP_SCRATCH_LEN <= $100, error, "zp.inc: ZP_SCRATCH block does not fit in page zero"
.assert ZP_PTRS + ZP_PTRS_LEN <= $100, error, "zp.inc: ZP_PTRS block does not fit in page zero"
.assert ZP_OVFLAG <= $FF, error, "zp.inc: ZP_OVFLAG is not in page zero"

; Pairwise disjointness: [A, A+ALEN) and [B, B+BLEN) do not overlap, i.e.
; A+ALEN <= B or B+BLEN <= A. Block ends are computed once for readability.
ZP_SCRATCH_END  = ZP_SCRATCH + ZP_SCRATCH_LEN
ZP_PTRS_END     = ZP_PTRS + ZP_PTRS_LEN
ZP_EDITOR_END   = ZP_EDITOR + ZP_EDITOR_LEN

.assert ZP_SCRATCH_END <= ZP_PTRS || ZP_PTRS_END <= ZP_SCRATCH, error, "zp.inc: ZP_SCRATCH overlaps ZP_PTRS"
.assert ZP_SCRATCH_END <= ZP_OVFLAG || ZP_OVFLAG + 1 <= ZP_SCRATCH, error, "zp.inc: ZP_SCRATCH overlaps ZP_OVFLAG"
.assert ZP_PTRS_END <= ZP_OVFLAG || ZP_OVFLAG + 1 <= ZP_PTRS, error, "zp.inc: ZP_PTRS overlaps ZP_OVFLAG"
.assert ZP_EDITOR_END <= ZP_SCRATCH || ZP_SCRATCH_END <= ZP_EDITOR, error, "zp.inc: ZP_SCRATCH overlaps the editor's zeropage block"
.assert ZP_EDITOR_END <= ZP_PTRS || ZP_PTRS_END <= ZP_EDITOR, error, "zp.inc: ZP_PTRS overlaps the editor's zeropage block"
.assert ZP_EDITOR_END <= ZP_OVFLAG || ZP_OVFLAG + 1 <= ZP_EDITOR, error, "zp.inc: ZP_OVFLAG overlaps the editor's zeropage block"

; ---------------------------------------------------------------------------
; Save / restore helpers.
;
;   zp_save_ptrs  area   copies ZP_PTR2/ZP_PTR3 (4 bytes) into area+0..+3
;   zp_restore_ptrs area copies them back
;   zp_save       area   copies ZP_SCRATCH (ZP_SCRATCH_LEN bytes) into
;                        area+0.., then ZP_PTR2/ZP_PTR3 after it —
;                        area must be ZP_SAVE_LEN bytes
;   zp_restore    area   copies them back
;
; Clobber A and X. The instruction sequence is exactly what the modules
; used to spell out by hand, so the C64 build is unchanged.
; ---------------------------------------------------------------------------
.macro zp_save_ptrs area
    lda ZP_PTR2
    sta area+0
    lda ZP_PTR2+1
    sta area+1
    lda ZP_PTR3
    sta area+2
    lda ZP_PTR3+1
    sta area+3
.endmacro

.macro zp_restore_ptrs area
    lda area+0
    sta ZP_PTR2
    lda area+1
    sta ZP_PTR2+1
    lda area+2
    sta ZP_PTR3
    lda area+3
    sta ZP_PTR3+1
.endmacro

.macro zp_save area
    ldx #0
:   lda ZP_SCRATCH,x
    sta area,x
    inx
    cpx #ZP_SCRATCH_LEN
    bne :-
    zp_save_ptrs area+ZP_SCRATCH_LEN
.endmacro

.macro zp_restore area
    ldx #0
:   lda area,x
    sta ZP_SCRATCH,x
    inx
    cpx #ZP_SCRATCH_LEN
    bne :-
    zp_restore_ptrs area+ZP_SCRATCH_LEN
.endmacro

.endif ; ZP_INC_INCLUDED
