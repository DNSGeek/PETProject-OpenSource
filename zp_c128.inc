; ============================================================================
; zp_c128.inc — C128 module scratch map
;
; Do not include this directly — include zp.inc, which selects the target.
;
; Source: C128 RAM memory map, https://www.zimmers.net/anonftp/pub/cbm/maps/
;         C128ram.txt (the CBM archive's zero page / page 3 allocation list).
;
; ---------------------------------------------------------------------------
; HOW THE C128 ZERO PAGE DIVIDES
; ---------------------------------------------------------------------------
;   $02-$8F  BASIC 7.0    142 bytes. Tokens, SYS registers, program/variable/
;                         array pointers, FP accumulators, DS$ descriptor,
;                         graphics work values.
;   $90-$F9  KERNAL +     106 bytes. ST, serial/tape/RS-232, jiffy clock,
;            screen editor  file tables, keyboard decode and buffer, all the
;                         screen editor state (cursor, margins, colors).
;   $FA-$FE  "Not used"     5 bytes. The only officially spare zero page.
;   $FF      BASIC scratch
;
; Five free bytes is nowhere near the 41 PETProject needs, so the port takes
; the other route: BASIC is banked out for the whole session and never
; called, which makes the entire $02-$8F region available. 142 bytes for a
; 41-byte requirement — 101 bytes of headroom.
;
; That premise EXCLUDES the script runner (modscr / modscrh), which jumps
; into BASIC and runs handlers inside the interpreter loop — BASIC 7.0 would
; own $02-$8F while they run. Both modules refuse to assemble under
; TARGET_C128 for that reason; see docs/c128-port-notes.md ("Script runner").
;
; The reason this is safe rather than merely convenient: the editor issues no
; sei/cli of its own and depends on the default KERNAL IRQ throughout (all 20
; GETIN sites, plus the jiffy clock at $A0-$A2 for cursor blink). So what the
; IRQ handler touches matters more than what our own calls touch. Every
; IRQ-updated location on the C128 sits at $90 or above — jiffy clock
; $A0-$A2, keyboard decode pointer $CC-$CD, key buffer and codes $D0-$D5,
; the cassette switch at $C0 (which the map explicitly annotates "Updated
; during IRQ"), and the screen editor block $E0-$F9. Nothing below $90 is
; IRQ-touched. The same holds for the KERNAL I/O we call: status $90, file
; tables $B7-$BC, device $BA, bank registers $C6-$C7 — all above the line.
;
; ---------------------------------------------------------------------------
; LAYOUT — packed from the bottom of the BASIC region
; ---------------------------------------------------------------------------
;   $02-$1B  editor .zeropage segment   26 B   (Tier 1 — UNCHANGED from C64)
;   $1C-$21  ZP_SCRATCH                  6 B
;   $22-$29  ZP_PTRS                     8 B   (four pointer pairs)
;   $2A      ZP_OVFLAG                   1 B
;                                       ----
;                                        41 B, occupying $02-$2A
;
; Two consequences worth knowing:
;
;   * Tier 1 does not move. petproject.cfg's `ZP: start = $02, size = $1A`
;     is already correct for the C128, so a C128 linker config differs from
;     the C64 one only in the areas that actually change (banking, load
;     addresses) — not in zero page.
;
;   * The two tiers are now CONTIGUOUS as well as disjoint. That was the goal
;     stated in docs/c128-port-notes.md: it makes non-overlap obvious rather
;     than incidental, and it clears the way to retire the KW_TOKEN alias in
;     editor.asm by giving colorize a byte of its own. Doing so means growing
;     ZP_EDITOR_LEN (and petproject.cfg) AND shifting the pool up; zp.inc's
;     disjointness asserts and editor.asm's link-time check fail the build
;     if only one of those moves.
;
; ---------------------------------------------------------------------------
; CONFIRMED ON HARDWARE
; ---------------------------------------------------------------------------
; The reasoning above comes from a static allocation map, which documents who
; OWNS each byte, not empirically what the ROM writes. It has held up: the
; C128 build runs on a real C128 with editing, module loads and disk I/O
; (September 2026). If this map ever changes, re-check with a poisoned-pattern
; test: fill $02-$2A with a known pattern, run the IDE, and confirm only
; PETProject's own writes appear.
; ============================================================================

ZP_EDITOR       = $02   ; must match petproject.cfg  ZP: start
ZP_EDITOR_LEN   = $1A   ; must match petproject.cfg  ZP: size

ZP_SCRATCH      = ZP_EDITOR + ZP_EDITOR_LEN     ; $1C
ZP_PTRS         = ZP_SCRATCH + 6                ; $22
ZP_OVFLAG       = ZP_PTRS + 8                   ; $2A
