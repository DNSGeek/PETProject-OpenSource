# PETProject — C128 Port Notes

Working reference for porting PETProject to run natively on a Commodore 128.
Not a manual — this is an engineering audit and plan. Everything in the
"Current state" sections is derived from the source tree and verified against
`build/editor.dbg`; items needing external confirmation are flagged
explicitly under [Open items](#open-items).

---

## Table of Contents

- [Scope](#scope)
- [Zero-page audit](#zero-page-audit)
- [Banking](#banking)
- [What ports for free](#what-ports-for-free)
- [Component status](#component-status)
- [Relocation strategy](#relocation-strategy)
- [Phasing](#phasing)
- [Open items](#open-items)

---

## Scope

**Target: native C128, 40-column VIC-IIe.**

A C128 already runs `petproject.d64` unchanged in C64 mode, so a native port
only earns its keep through things C64 mode cannot offer. At 40 columns those
are: bank-1 RAM (a bigger buffer, and REU-free scripting), burst-mode disk,
and 2 MHz bursts.

80-column VDC output is **explicitly out of scope**. It was priced and
rejected: the VDC keeps screen and attribute RAM in its own 16K behind
`$D600`/`$D601`, which would require abstracting roughly 350 direct screen
writes across nine files, re-doing reverse video as an attribute rather than
screen-code bit 7, and making width a runtime property (81 hardcoded `40`s in
`moddsk.asm` alone). Choosing 40 columns removes all of that.

### Note on 2 MHz

The 40-column screen **cannot** be displayed at 2 MHz — the VIC-IIe can't
sustain its fetches, and the KERNAL's `FAST` blanks the display rather than
show garbage. The VDC is immune because it is an independent chip, which is
why 80-column mode runs at 2 MHz by default.

So on this target 2 MHz is a _blank-screen burst_ around compute-only work:
the assembler's passes, tokenize/detokenize, renumber, search/replace. Two
constraints:

- It kills the progress spinner (`SPIN_CELL`, `modasm.asm:177`,
  `moddis.asm:83`) — nothing in color RAM is visible while blanked.
- **Do not hold 2 MHz across KERNAL disk I/O.** CIA timers are fed by the
  system clock and serial timing depends on them (see the note at
  `modasm.asm:2588`). Bracket the 2 MHz window tightly around computation,
  excluding file reads.

A partial-credit alternative — toggling `$D030` to run 2 MHz only during
vertical blank and border — keeps the display up but nets only ~10–12%.
Not worth the complexity.

---

## Zero-page audit

PETProject uses **41 bytes** of zero page across two disjoint tiers, plus two
read-only system locations.

### Tier 1 — editor-owned block, `$02–$1B` (26 bytes)

Declared as a `.zeropage` segment at `editor.asm:126`, placed by the `ZP:`
entry in `petproject.cfg`.

| Range     | Sz  | Symbol       | Role                                    |
| --------- | --- | ------------ | --------------------------------------- |
| `$02-$03` | 2   | `GAP_START`  | gap buffer                              |
| `$04-$05` | 2   | `GAP_END`    | gap buffer                              |
| `$06-$07` | 2   | `BUF_PTR`    | buffer walk                             |
| `$08-$09` | 2   | `SCREEN_PTR` | screen RAM pointer                      |
| `$0A-$0B` | 2   | `TOP_LINE`   | viewport origin                         |
| `$0C`     | 1   | `LEFT_COL`   | horizontal scroll                       |
| `$0D-$0E` | 2   | `TMP`        | scratch; aliased `CLR_SCOL` / `CLR_TMP` |
| `$0F`     | 1   | `SAVED_X`    | X preservation                          |
| `$10`     | 1   | `CURSOR_ROW` |                                         |
| `$11`     | 1   | `CURSOR_COL` |                                         |
| `$12`     | 1   | `COL_SAVE`   | aliased `CLR_LCOL`                      |
| `$13-$14` | 2   | `TXT_PTR`    | text scratch pointer                    |
| `$15-$16` | 2   | `LPTR`       | load/save + module trampoline           |
| `$17-$18` | 2   | `CLR_PTR`    | color RAM pointer                       |
| `$19`     | 1   | `CLR_KWLEN`  |                                         |
| `$1A-$1B` | 2   | `CLR_CTMP`   | colortab walker                         |

**This block is already fully relocatable.** No code references these by
literal address; everything resolves through the ca65 zeropage segment.
Relocating it is a one-line change (`start = $02`) in a C128 linker config,
provided a 26-byte contiguous hole exists. ca65 keeps the segment in
declaration order, so all pointer pairs stay adjacent wherever the block
lands.

### Tier 2 — module scratch, `$3A–$3F` and `$F7–$FF` (15 bytes)

> **Status: converted.** These addresses now come from `zp.inc`, which
> selects `zp_c64.inc` or `zp_c128.inc` (`-D TARGET_C128`). The table below
> describes the C64 map, which is unchanged. See
> [Relocation strategy](#relocation-strategy) for what remains.

| Range     | Used by                                        | As                                              |
| --------- | ---------------------------------------------- | ----------------------------------------------- |
| `$3A-$3B` | modtok, modsct, moddet, modasm, moddis, modren | `LINENO` / `KW_TOKEN`+`KW_XSAVE` / `TMP`        |
| `$3C-$3D` | above + modscr, modscrh                        | `TMP16` / `TMP2` / `NZFLAG`+`KWTAB` / `HND_TMP` |
| `$3E-$3F` | modtok, modsct, moddet, modasm, moddis, modren | `IN_STRING`+`AFTER_REM` / `TMP3` / `OVFLAG`     |
| `$F7-$F8` | modtok, modsct, moddet                         | `LINK_PTR` / `COPY_SRC`                         |
| `$F9-$FA` | modtok, modsct, moddet                         | `BASIC_ADDR` / `COPY_DST`                       |
| `$FB-$FC` | all seven compute modules                      | `SRC_PTR`                                       |
| `$FD-$FE` | all seven compute modules                      | `DST_PTR`                                       |
| `$FF`     | modtok, modsct                                 | `OVFLAG`                                        |

### Cross-tier alias

`editor.asm:149` declares `KW_TOKEN = $3A` so colorize can reach into module
scratch. The comment justifies it — the editor never calls tokenizer code
directly — and it holds today. It is a coupling that must move in lockstep
with any relocation, and it should be retired if the two tiers become
contiguous.

### Save/restore discipline — inconsistent, and not load-bearing

| Module                                  | Saves                        | Does not save                      |
| --------------------------------------- | ---------------------------- | ---------------------------------- |
| modasm, moddis, modren                  | `$3A-$3F` + `$FB-$FE` (10 B) | `$F7-$FA`, `$FF`                   |
| moddsk                                  | `$FB-$FE` (4 B)              | — consistent, touches nothing else |
| moddet, modtok, modsct, modscrh, modsfr | **nothing**                  | everything they use                |

An earlier revision of this document called the inconsistency "the main hazard
in the whole port." **That was wrong.** On examination the saves protect
nothing that anything depends on:

- **The editor holds no state in the pool.** Its only use is `KW_TOKEN`, and
  every read is preceded by a write in the same routine
  (`colorize.asm:552`→`581`, `colorize.asm:770`→`772`,
  `editor.asm:3068`→`3072`). It is transient scratch, never live across a
  module call. Nothing else in `editor.asm`, `colorize.asm`, `loadsave.asm`
  or `modules.asm` touches the pool at all.
- **The saves carry no stated rationale** — the comments read only "Save ZP".
- **What they would nominally protect is moot.** `$3A-$3F` is BASIC's and
  `$F7-$FE` is RS-232's, but the editor quits through BASIC _cold start_
  (`editor.asm:542`), which reinitialises all of it.
- **The one real in-flight hazard is not addressed by saving.** The C64 KERNAL
  IRQ using `$FB`/`$FC` for cursor blink (`modasm.asm:260`) is a collision
  _during_ execution; entry/exit save/restore does nothing for it. `sei` does,
  which is why modasm holds one.

So the requirement on any relocation is **disjointness alone** — the two tiers
must not overlap. Making saving universal is _not_ a substitute for that, and
is not worth doing on its own merits: it would mean threading save/restore
through every exit path in five working modules (`modsfr` has 31 `rts`,
`modsct` 30, `modscrh` 18), risking a regression on some error path in
exchange for no identified benefit.

**Enforce disjointness at build time instead.** `petproject.cfg` already sets
`define = yes` on both the `ZP` memory area and the `ZEROPAGE` segment, so
`editor.asm` can `.import __ZP_START__, __ZP_SIZE__` and assert non-overlap
against `ZP_SCRATCH` / `ZP_PTRS`. It needs the `lderror` action rather than
`error`, since those values resolve at link time. Zero runtime cost, zero
regression risk, and it fails the build the moment a C128 map puts the tiers
on top of each other — which is the only scenario that ever mattered.

### System ZP — read, not owned

| Addr        | Symbol         | Sites                                                    | C128          |
| ----------- | -------------- | -------------------------------------------------------- | ------------- |
| `$A2`       | `JIFFY_LO`     | `editor.asm:32`, `moddsk.asm:110`, `modscrh.asm:441,444` | same address  |
| `$BA`       | `FA` (device)  | `editor.asm:26`                                          | same address  |
| `$00`/`$01` | processor port | 6 banking sites                                          | **see below** |

### IRQ interaction

The editor issues no `sei`/`cli` of its own — it relies on the default KERNAL
IRQ for keyboard scanning (all 20 `GETIN` sites) and reads `$A2` for cursor
blink. So the ZP set to avoid is defined by **what the KERNAL IRQ handler
touches 60 times a second**, not merely by the routines PETProject calls.
That is a strictly larger set.

`modasm` is the exception: it holds `sei` across an _entire assembly_, on
explicitly C64-specific reasoning (`modasm.asm:260` — the C64 KERNAL IRQ uses
`$FB`/`$FC` as cursor-blink scratch, which would corrupt `SRC_PTR`). That
premise must be **re-derived** for the C128, not inherited. A multi-second
`sei` is riskier there, and the better answer may be to relocate `SRC_PTR`
and drop the `sei` entirely.

### C128 zero-page map (resolved)

Source: the CBM archive's C128 RAM map,
<https://www.zimmers.net/anonftp/pub/cbm/maps/C128ram.txt>.

The C128 zero page divides cleanly in two, with almost nothing spare:

| Range     | Owner                                                                                                                                  | Size  |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `$02-$8F` | BASIC 7.0 — tokens, SYS registers, program/variable/array pointers, FP accumulators, `DS$`, graphics work values                       | 142 B |
| `$90-$F9` | KERNAL + screen editor — `ST`, serial/tape/RS-232, jiffy clock, file tables, keyboard decode and buffer, all cursor/margin/color state | 106 B |
| `$FA-$FE` | **"Not used"** — the only officially spare zero page                                                                                   | 5 B   |
| `$FF`     | BASIC scratch                                                                                                                          | 1 B   |

Five spare bytes against a 41-byte requirement, so the
[relocation strategy](#relocation-strategy) is confirmed as the only viable
route: **bank BASIC out and claim `$02-$8F`.** 142 bytes for 41 leaves 101
bytes of headroom.

**Why that is safe, not merely convenient.** The binding constraint is the
KERNAL IRQ, which runs throughout (the editor issues no `sei`/`cli` of its
own). Every IRQ-touched location on the C128 sits at `$90` or above — jiffy
clock `$A0-$A2`, keyboard decode pointer `$CC-$CD`, key buffer and codes
`$D0-$D5`, the cassette switch at `$C0` which the map explicitly annotates
"Updated during IRQ", and the screen editor block `$E0-$F9`. Nothing below
`$90` is IRQ-touched. The KERNAL I/O we call sits above the line too: status
`$90`, file tables `$B7-$BC`, device `$BA`, bank registers `$C6-$C7`.

**Adopted layout** — packed from the bottom of the BASIC region, implemented
in `zp_c128.inc`:

| Range     | Contents                            | Size |
| --------- | ----------------------------------- | ---- |
| `$02-$1B` | editor `.zeropage` segment (Tier 1) | 26 B |
| `$1C-$21` | `ZP_SCRATCH`                        | 6 B  |
| `$22-$29` | `ZP_PTRS` (four pointer pairs)      | 8 B  |
| `$2A`     | `ZP_OVFLAG`                         | 1 B  |

Two consequences:

- **Tier 1 does not move.** `petproject.cfg`'s `ZP: start = $02, size = $1A`
  is already correct for the C128, so a C128 linker config will differ only
  where something actually changes — banking and load addresses, not zero
  page. Strategy step 1 below is therefore a no-op.
- **The tiers are now contiguous as well as disjoint**, which was the stated
  goal: non-overlap becomes obvious rather than incidental, and the
  `KW_TOKEN` alias can be retired by giving colorize a byte of its own.

**Residual empirical check.** The above comes from a static allocation map,
which documents who _owns_ each byte rather than what the ROM demonstrably
writes. Before trusting it in anger, run a poisoned-pattern test on a real
C128 or in VICE: fill `$02-$2A` with a known pattern, exercise the IDE
including disk I/O, and confirm only PETProject's own writes appear.

---

## Banking

### `$01` does not bank memory on a C128 — and fails silently

On the 8502, `$01` is the tape / caps-lock sense port. Memory banking is the
MMU's job. So every existing `lda #$36 / sta $01` will **not** error — it
does nothing useful while writing junk to the tape lines, leaving the wrong
memory visible. Silent wrong-memory is the worst failure mode to debug, so
these should be converted **first**, before anything else is tested.

Sites:

| File:line          | Current | Purpose                            |
| ------------------ | ------- | ---------------------------------- |
| `modasm.asm:273`   | `#$36`  | page BASIC out to run from `$A000` |
| `moddsk.asm:214`   | `#$37`  | restore                            |
| `modscr.asm:207`   | `#$37`  | restore, from `$033C` trampoline   |
| `modscrh.asm:1080` | `#$36`  | page out for MODASM handoff        |
| `modscrh.asm:1126` | `#$37`  | restore                            |
| `modules.asm:724`  | `#$36`  | module execution banking           |
| `modules.asm:735`  | `#$37`  | restore                            |

Use the MMU's `$FF01–$FF04` preconfiguration registers so each switch stays a
single store, preserving the shape of the existing code.

### MMU configuration register

`$D500`, mirrored at `$FF00`, with preconfiguration registers `$FF01–$FF04`
that load a stored config in a single store. The `$FF00–$FF04` window is
visible from **every** bank, which is what makes it usable from switching
code.

| Field        | Controls                       |
| ------------ | ------------------------------ |
| bit 0        | `$D000-$DFFF` — I/O vs ROM/RAM |
| bit 1        | `$4000-$7FFF`                  |
| bits 2-3     | `$8000-$BFFF`                  |
| **bits 4-5** | **`$C000-$FFFF`**              |
| bits 6-7     | RAM bank select                |

Essentially **one config covers the whole session** — `$0E`: RAM from
`$0000-$BFFF`, I/O at `$D000`, KERNAL ROM above. That is strictly better than
the C64 arrangement, because `$A000-$BFFF` is simply RAM. The `#$36`/`#$37`
dance around the big modules does not get translated, it **disappears** —
along with the "do not restore `$01` while executing here" hazard at
`modasm.asm:449`.

_(CR bit assignments and the `$0E` value want confirming against the C128
Programmer's Reference — see [Open items](#open-items).)_

### The `$C000` collision — the real work in this phase

**Bits 4-5 cover `$C000-$FFFF` as a single unit.** On the C128 `$C000-$CFFF`
is the screen editor ROM, sharing that field with the KERNAL at `$E000`. So
**RAM at `$C000` and KERNAL ROM at `$E000` are mutually exclusive.**

PETProject leans on `$C000-$CFFF` heavily:

| What                          | Detail                                                                                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 6 modules load there          | moddet, modtok, moddsk, modren, modsfr, modscrh — largest is moddsk at 3,255 bytes                                                   |
| modasm's entire working state | 44 equates at `$C0xx` — symbol table, PC, pass counter, error state, output filename, `ZP_SAVE`, gap pointers (`modasm.asm:115-151`) |

That is 7 of 10 modules. On the C64 it was the natural choice: `$C000-$CFFF`
is the permanent 4 K RAM gap between BASIC and I/O. On the C128 it is the one
region you cannot have while keeping the KERNAL.

A `$C000`-resident module also cannot trampoline its way out — it would need
RAM at `$C000` to execute and ROM at `$E000` to call the KERNAL, and moddsk
is almost entirely KERNAL I/O.

#### Resolution: rehome, don't trampoline

Keep config `$0E` for the whole session and move everything off `$C000`. The
budget works:

```
editor BSS ends           $8C1E
free below module area    $8C1F-$9FFF   5,089 bytes
must be rehomed           $C000-$CFFF   4,096 bytes
                                        ------------
spare                                     993 bytes
```

Two things to design around:

- **That margin shrinks as the editor's BSS grows.** Wants a link-time
  assertion — same technique as the ZP overlap check, fail the build rather
  than discover it as corruption.
- **The modscrh/modasm choreography survives unchanged in shape.** modscrh
  currently stashes itself out of `$C000-$CFFF` to REU `$013000` so modasm can
  use that space as scratch (`modscrh.asm:102`). Relocating both is
  mechanical — same dance, different address.

The alternative — all-RAM bank 0 with KERNAL calls trampolined through common
RAM — preserves the memory map exactly but taxes every I/O call in the
project. Rejected for that reason.

**Sequencing note:** the rehoming is the substantive work, it is independent
of the MMU stores, and it can be **done and tested entirely on the C64** —
moving modules from `$C000` to `$8C20` is a valid C64 layout too. That turns
the risky part into something verifiable on hardware you already have, before
any C128-specific code exists. Do it first; the MMU stores are small once
nothing depends on `$C000`.

### Trampolines must move

`modscr.asm:201` and `modscrh.asm:94` place bank-switch trampolines at `$033C`
(the C64 cassette buffer). The C128 cassette buffer is at `$0B00`, so `$033C`
is wrong regardless of banking — and page 3 is much more crowded on the C128
than the C64, so there is no drop-in replacement. See
[Open items](#open-items) #2.

Rehoming `$C000` _reduces_ how much trampolining is needed, since one config
then covers the session.

### `SETBNK`

C128 KERNAL LOAD/SAVE take a bank argument via `SETBNK` (`$FF68`), which must
be called before each. Few sites, since everything funnels through wrappers:
`modules.asm:661` (module loader) and the `loadsave.asm` paths.

---

## What ports for free

Choosing 40 columns makes the largest category of work vanish:

- **Screen and color RAM.** The C128's 40-column VIC screen is at `$0400`
  with color at `$D800` — identical to the C64. All direct writes across
  `editor.asm` (118 refs), `moddsk.asm` (97), `modules.asm` (50),
  `loadsave.asm` (24), `modasm.asm` (23), and the rest work unchanged.
- **Layout.** `COLS = 40`, the `row40_lo`/`row40_hi` tables
  (`editor.asm:1528`), `LEFT_COL` horizontal scrolling, popup geometry
  (`POP_LEFT`/`POP_WIDTH`), and `ora #SCR_REVERSE` reverse video are all
  still correct.
- **Instruction set.** The 8502 is instruction-compatible with the 6502,
  illegal opcodes included. `modasm` and `moddis` need no ISA work.
- **Keyboard.** `GETIN` is compatible. The C128's TAB key already emits `$09`,
  matching `KEY_CTRL_I`.
- **`$A000–$BFFF` modules get simpler.** That range is plain bank-0 RAM on the
  C128, so the "don't restore `$01` while executing here" hazard
  (`modasm.asm:449`) largely stops being a hazard.
- **Detokenizer tables.** `moddet` already uses an embedded keyword table
  (`moddet.asm:436`) rather than reading BASIC ROM at `$A09E`, so it carries
  no ROM dependency.

---

## Component status

| Component      | C128 effort | Notes                                             |
| -------------- | ----------- | ------------------------------------------------- |
| `editor.asm`   | **Low**     | ZP relocation via cfg; one line for the quit path |
| `colorize.asm` | **None**    | aliases editor ZP only; moves with it             |
| `loadsave.asm` | **Low**     | add `SETBNK`                                      |
| `modules.asm`  | **Low**     | MMU conversion + `SETBNK`                         |
| `modsfr.asm`   | **None**    | no banking, no ROM calls                          |
| `moddet.asm`   | **Low**     | ZP scratch equates only                           |
| `modtok.asm`   | **Low**     | ZP scratch equates only                           |
| `modren.asm`   | **Low**     | ZP scratch + save loop                            |
| `moddis.asm`   | **Low**     | ZP scratch + save loop                            |
| `modasm.asm`   | **Medium**  | MMU + ZP + re-derive the `sei` decision           |
| `moddsk.asm`   | **Medium**  | MMU + ZP + `SETBNK`                               |
| `modsct.asm`   | **High**    | REU staging at `$B000`; BASIC ABI                 |
| `modscr.asm`   | **High**    | BASIC ROM entry points; `$B000` staging           |
| `modscrh.asm`  | **Highest** | 12 BASIC ROM entry points; BASIC 2.0 ZP ABI       |

### The script runner is a BASIC-ABI problem, not a ZP problem

This is the single most-affected subsystem, and it is worse than it first
appears. It hardcodes **12 C64 BASIC ROM entry points**, none of which exist
at those addresses in BASIC 7.0:

| Addr    | Symbol                  | Site                                 |
| ------- | ----------------------- | ------------------------------------ |
| `$A7AE` | `NEWSTT` / `BASIC_RUNC` | `modscr.asm:78`, `modscrh.asm:47,58` |
| `$A871` | `RUNC`                  | `modscr.asm:79`                      |
| `$A659` | `CLR`                   | `modscr.asm:80`, `modscrh.asm:57`    |
| `$A533` | `RELINK`                | `modscrh.asm:56`                     |
| `$A437` | `ERROR`                 | `modscrh.asm:75`                     |
| `$A7E7` | `GONE_ORIG`             | `modscrh.asm:48`                     |
| `$B08B` | `PTRGET`                | `modscrh.asm:73`                     |
| `$B79E` | `GETBYT`                | `modscrh.asm:50`                     |
| `$AD9E` | `FRMNUM`                | `modscrh.asm:535`                    |
| `$B1AA` | `AYINT`                 | `modscrh.asm:536`                    |
| `$E544` | `CLRSCR` (KERNAL)       | `modscr.asm:82`                      |
| `$E394` | BASIC cold start        | `editor.asm:542`                     |

Plus the BASIC 2.0 zero-page ABI: `$2B`/`$2D` (TXTTAB/VARTAB), `$37` (MEMSIZ),
`$47` (VARPNT), `$7A`/`$7B` (TXTPTR), and `$14`/`$15` as AYINT's big-endian
output (`modscrh.asm:540`). It also stages into `$B000` (`modscr.asm:96`,
`modsct.asm:149`), which is BASIC HI ROM territory on the C128.

**Recommendation: cut the script runner from the first C128 release.** The
editor, assembler, disassembler, renumber, disk utility and search modules
have no BASIC ROM dependency at all and can ship without it.

Note that `editor.asm:542` (`jmp $E394`) needs replacing regardless — it is
the normal quit path, not part of the script runner.

---

## Relocation strategy

**Claim BASIC 7.0's zero page wholesale.**

PETProject banks BASIC out for its entire session and — apart from the script
runner, which is being cut from release 1 — never calls it. The KERNAL's
reserved ZP set is the smaller and better-documented half; BASIC 7.0's is the
large low region. Bank BASIC out at startup, stay clear of the KERNAL set,
and there is room for **both** tiers in one contiguous region.

That is worth more than just fitting: contiguity makes the two tiers trivially
disjoint — the one property the port actually requires (see
[Save/restore discipline](#saverestore-discipline--inconsistent-and-not-load-bearing))
— and it allows the `KW_TOKEN` alias to be retired.

Mechanically:

1. **Tier 1** — ✅ **no change needed.** The adopted C128 map leaves the
   editor block at `$02-$1B`, so `petproject.cfg`'s existing `ZP:` entry is
   already correct for both targets.
2. **Tier 2** — ✅ **done.** The literal equates and the raw `lda $3A,x` /
   `sta $FB` save loops are now symbolic, resolving through `zp.inc`.
   Verified twice over: the C64 build is byte-for-byte identical to the
   pre-conversion output, and a `-D TARGET_C128` build relocates cleanly
   (every `lda (SRC_PTR),y` moved `$FB`→`$26`, same counts, no stale
   references, identical binary sizes).
3. **Assert non-overlap at link time** via `__ZP_START__` / `__ZP_SIZE__` and
   `lderror`, as described above. _(Not yet done. Small, safe, independent of
   the C128 map — can land at any point.)_

   This replaces an earlier plan to make ZP saving universal across all
   modules. That plan was dropped: it guarded against nothing real and would
   have meant editing every exit path in five working modules.

#### Files

| File          | Role                                                                           |
| ------------- | ------------------------------------------------------------------------------ |
| `zp.inc`      | target dispatch, derived `ZP_PTR0..3`, contract + assertions                   |
| `zp_c64.inc`  | the historical C64 map — `$3A`, `$F7`, `$FF`                                   |
| `zp_c128.inc` | the C128 map — `$1C`, `$22`, `$2A`, with the derivation and the residual check |

Each module now aliases its own local names onto pool slots
(`SRC_PTR = ZP_PTR2`, `TMP = ZP_SCRATCH+0`, …), so module code reads exactly
as before and the diff stays small. Converted: `editor.asm` (the `KW_TOKEN`
alias), `modasm`, `moddet`, `moddis`, `modren`, `moddsk`, `modscr`,
`modscrh`, `modsct`, `modtok`. `modsfr` needed no change — it uses no pool
scratch.

BASIC/KERNAL ABI addresses (`TXTTAB`, `VARTAB`, `MEMSIZ`, `VARPNT`, `TXTPTR`,
AYINT's `$14`/`$15`, `JIFFY_LO`, `FA`) were deliberately **left as literals**.
They are fixed by the ROM being called, not ours to relocate, and folding them
into the pool would have obscured that distinction.

Single source tree throughout — `.if TARGET_C128` conditionals plus parallel
`.cfg` files, not a fork. The module configs barely change; `$A000` and
`$C000` remain valid load addresses.

---

## Phasing

**Phase 0 — zero page.** ✅ **Done.** Tier 2 include-file conversion, C128 map
resolved and adopted, Tier 1 confirmed to need no change. C64 build verified
byte-identical throughout; `-D TARGET_C128` assembles and links.

**Phase 1 — rehome `$C000`.** Move the six `$C000` modules and modasm's 4 K of
working state below `$A000`, per
[The `$C000` collision](#the-c000-collision--the-real-work-in-this-phase).
Deliberately first, and deliberately **done on the C64**: the new layout is
valid there, so it is testable on real hardware before any C128-specific code
exists. Add the link-time assertion guarding the 993-byte margin.

**Phase 2 — banking.** MMU conversion (7 sites), trampoline relocation,
`SETBNK`, quit path. Small once nothing depends on `$C000`. Ends with a native
C128 build that boots.

**Phase 3 — build and packaging.** `TARGET_C128` conditionals, parallel
`.cfg` set, C128 autoboot sector in `make_disk.py`. One disk can carry both
builds — the C64 BASIC stub and the C128 boot sector select between them, so
no runtime machine detection is needed.

**Phase 4 — the payoff.** In value-per-effort order:

1. **REU-free scripting.** `modscr.asm` stashes `$0801–$9FFF` to REU `$009000`
   purely to make room. Bank 1 does that job, which would remove the one
   hardware requirement in the README. (Gated on the script runner rework.)
2. **Burst mode** with a 1571/1581 — retires the "use a fastloader cartridge"
   advice.
3. **2 MHz bursts** around the assembler's passes, screen blanked, disk I/O
   excluded.
4. **Bigger buffer** via bank 1. Real, but the most invasive: the gap buffer
   needs a windowing scheme rather than per-byte far access through
   `INDFET`/`INDSTA` (`$FF74`/`$FF77`), which are correct but slow.

BASIC 7.0 token support — extending `modtok`, `moddet`, `colorize` and
`modren` to the two-byte `$CE xx` / `$FE xx` tokens, including which new
keywords take line-number arguments (`TRAP`, `RESUME`, the `GO` forms) — is a
separate content project, not part of the port.

---

## Open items

Claims not derived from the source tree. Reference for C128 hardware
allocation throughout: the CBM archive's C128 RAM map,
<https://www.zimmers.net/anonftp/pub/cbm/maps/C128ram.txt>.

1. ~~**C128 KERNAL zero-page reservation list.**~~ ✅ **Resolved** — see
   [C128 zero-page map](#c128-zero-page-map-resolved). One residual empirical
   check is noted there.
2. **Trampoline placement — reopened, and harder than first thought.** An
   earlier revision of this document suggested putting the relocated
   trampolines somewhere in page 3, on the reasoning that the C128's default
   bottom common RAM is `$0000–$03FF` so anything below `$0400` is visible
   from every bank. The visibility argument holds, but **page 3 is far more
   crowded on the C128 than on the C64** — `$0334-$0349` editor indirect
   vectors, `$034A-$034D` IRQ keyboard buffer, `$0354-$035D` tab-stop
   bitmaps, `$0362-$0376` file tables, `$0380-$03BF` CHRGET, `$03C0-$03FF`
   bank-relative fetch/poke. Only small gaps remain, and the C64's `$033C`
   cassette buffer does not exist there as free space.

   The likelier answer is the C128 cassette buffer at **`$0B00-$0BFF`** (256
   bytes, free when tape is unused) — but that is outside the default 1 K
   bottom common RAM, so it needs the MMU's RCR (`$D506`) set to a 4 K bottom
   common region (`$0000-$0FFF`) to be bank-visible. Both halves of that need
   confirming: that `$0B00` is genuinely free in our configuration, and the
   RCR setting.

3. **MMU configuration register details** — the CR bit assignments tabulated
   under [Banking](#mmu-configuration-register), and that `$0E` is the right
   whole-session config value (RAM `$0000-$BFFF`, I/O, KERNAL ROM). The
   consequence that matters — bits 4-5 covering `$C000-$FFFF` as one unit, and
   therefore the `$C000` collision — follows directly from these, so confirm
   before committing to the rehoming layout.
4. **`RPTFLG` at `$028A`** (`editor.asm:33`) — confirm the address and that
   `$80` still means "all keys repeat" on the C128.
5. **The `$0200–$0222` boot / module parameter block** (`modules.asm:63`)
   overlaps the C128 KERNAL input buffer. Interactive input uses `GETIN` so it
   is likely safe, but `moddsk`'s drive-status reads go through `CHRIN`, which
   does use that buffer.
6. **C128 BASIC cold-start entry** to replace `jmp $E394`. `jmp ($FFFC)` is
   the safe fallback.
