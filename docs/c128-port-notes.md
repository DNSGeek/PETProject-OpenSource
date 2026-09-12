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

**This block is relocatable, with one dependent.** `editor.asm`, `colorize.asm`,
`loadsave.asm` and `modules.asm` resolve every one of these through the ca65
zeropage segment. `modsfr.asm` does not — it is a separately linked PRG that
borrows six of them (`GAP_START`, `GAP_END`, `CURSOR_ROW`, `CURSOR_COL`,
`TXT_PTR`, `LPTR`) by offset. Those offsets are now expressed as
`ZP_EDITOR + n` from `zp.inc`, and `editor.asm` asserts at link time both that
`petproject.cfg`'s `ZP:` line matches `ZP_EDITOR`/`ZP_EDITOR_LEN` and that the
six symbols still sit at the offsets `modsfr` expects. So relocating the block
means changing the target map in `zp.inc` and `petproject.cfg` together
(provided a 26-byte contiguous hole exists); moving only one fails the build.
ca65 keeps the segment in declaration order, so all pointer pairs stay adjacent
wherever the block lands.

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
- **There is no in-flight hazard on the C64.** An earlier revision claimed the
  C64 KERNAL IRQ uses `$FB`/`$FC` for cursor blink (the rationale that used to
  sit on modasm's `sei`). It does not: the IRQ path uses `$A0-$A2`, `$C5`/`$C6`/
  `$CB`, `$CC-$CF`, `$D1-$D6` and `$F3-$F6`, and `$FB-$FE` are the documented
  free user bytes — `moddet`, `modtok` and `moddsk` run on them with IRQs
  enabled. modasm and moddis keep their `sei` as a precaution only.

So the requirement on any relocation is **disjointness alone** — the two tiers
must not overlap. Making saving universal is _not_ a substitute for that, and
is not worth doing on its own merits: it would mean threading save/restore
through every exit path in five working modules (`modsfr` has 31 `rts`,
`modsct` 30, `modscrh` 18), risking a regression on some error path in
exchange for no identified benefit.

**Disjointness is enforced at build time.** Each target map declares the
editor block as `ZP_EDITOR`/`ZP_EDITOR_LEN`, and `zp.inc` asserts that the
three pool blocks are pairwise disjoint from each other and from that block.
`petproject.cfg` sets `define = yes` on the `ZP` memory area, so `editor.asm`
imports `__ZP_START__`/`__ZP_SIZE__` and asserts with `lderror` that the cfg
agrees with the map. Zero runtime cost, and the build fails the moment a map
puts the tiers on top of each other or the cfg drifts from the map.

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

`modasm` (and `moddis`) hold `sei` across their entire run. The comment that
used to justify it — that the C64 KERNAL IRQ uses `$FB`/`$FC` as cursor-blink
scratch — was wrong (see above); the `sei` is a precaution, not a zero-page
requirement, on either target. A multi-second `sei` is riskier on the C128
(serial timing), so dropping it is an option for the port rather than a
constraint on it.

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

Done: each site is now `.ifdef TARGET_C128` — a single `sta $FF00` of the
session config where the module wants to assert its map (modasm, moddsk),
and nothing at all in the loader, whose `$36`/`$37` dance exists only to
expose RAM at `$A000` that the session config already exposes. The
preconfiguration registers turned out to be unnecessary: `$FF00` is visible
from every bank, so one immediate store is already a single instruction.

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

_Confirmed in VICE: the editor sets `$0E` as its first instruction and runs the
whole session under it; the monitor reads `$FF00 = $0E` at the idle loop, and
the BSS at `$3F03-$8F70` (under BASIC ROM in BASIC's own map) is live._

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

Keep config `$0E` for the whole session and move everything off `$C000`.

The budget is tighter than a first look suggests, because BASIC 7.0's program
text starts at `$1C01`, not `$0801`: a `LOAD`/`RUN`-able editor sits 5 K
higher on the C128 than on the C64.

```
editor at $0801 (C64)     ends $8C1E    free below $A000  5,089 bytes
editor at $1C01 (C128)    ends $A01E    free below $A000       -31 bytes
must be rehomed           $C000-$CFFF   4,096 bytes
```

So the rehomed region cannot simply slot in under `$A000`; something has to
give. The adopted layout (`layout.inc`, `petproject_c128.cfg`,
`module_c128.cfg`, `modsfr_c128.cfg`) keeps `MOD_HI` at `$A000-$BFFF` so
modasm, moddis and modsct share their C64 linker configs, keeps modasm's
symbol table at 400 entries (its state block is exactly 4 K), puts the
rehomed region at `$9000-$9FFF`, and pays for it with the buffer:

```
$1C01-$8F1E   editor, EDITOR_BUF_SIZE = $4F00 (19.75 K, was 24 K)
$9000-$9FFF   MOD_LO  — moddet, modtok, moddsk, modren, modsfr; modasm state
$A000-$BFFF   MOD_HI  — modasm, moddis, modsct
```

The buffer comes back — and then some — with a bank-1 buffer (Phase 4). The
alternative of a boot-sector load at `$1300` would recover 2.25 K of it at the
cost of losing the plain `RUN` launch; not taken.

Two things to design around:

- **The margin is 225 bytes and is enforced by the linker.** The editor's MAIN
  area in `petproject_c128.cfg` ends at `$9000`; if BSS grows past it, ld65
  reports a MAIN overflow. `editor.asm` also asserts (lderror) that the cfg's
  load address and MAIN end match `EDITOR_LOAD` / `EDITOR_END` in
  `layout.inc`, and every module asserts that its cfg's `__MAIN_START__`
  matches `MOD_LO_BASE` / `MOD_HI_BASE` — the same constants the loader table
  in `modules.asm` is built from. A cfg, `layout.inc` and the loader cannot
  disagree without failing the link.
- **The modscrh/modasm choreography survives unchanged in shape.** modscrh
  currently stashes itself out of `$C000-$CFFF` to REU `$013000` so modasm can
  use that space as scratch (`modscrh.asm:102`). Relocating both is
  mechanical — same dance, different address.

The alternative — all-RAM bank 0 with KERNAL calls trampolined through common
RAM — preserves the memory map exactly but taxes every I/O call in the
project. Rejected for that reason.

**Sequencing note:** the rehoming is independent of the MMU stores. At the
source level it is done: modasm's 44 state equates are `ASM_STATE + $xx` with
`ASM_STATE = MOD_LO_BASE`, the modules emit their PRG header from the
linker's `__MAIN_START__`, and `modules.asm` builds its load table from
`layout.inc`. The C64 build is byte-identical to before. What remains is
run-time: the MMU stores, `SETBNK`, the trampolines and the quit path.

### Trampolines must move

`modscr.asm:201` and `modscrh.asm:94` place bank-switch trampolines at `$033C`
(the C64 cassette buffer). The C128 cassette buffer is at `$0B00`, so `$033C`
is wrong regardless of banking — and page 3 is much more crowded on the C128
than the C64, so there is no drop-in replacement. See
[Open items](#open-items) #2.

Moot for the C128 build as shipped: those are the only two trampolines in the
tree and both live in the script runner, which refuses `TARGET_C128`. Nothing
else needs one — one config covers the session.

### Bank-1 buffer

The MMU selects the RAM bank for all non-common memory at once, so code and
the data it addresses natively must share a bank, and a bank has only
`$4000-$BFFF` (32 K) outside ROM and I/O. That is why the first C128 layout
ended up with a 19.75 K buffer: the editor, its buffer and the modules were
all squeezed into bank 0 under `$C000`. The bank-1 layout splits the machine
three ways instead (`layout.inc`, "C128"):

- **The editor lives in common RAM.** `c128_init` sets the MMU's RAM
  configuration register to a 16 K bottom common area, so `$0000-$3FFF` is
  the same physical memory in every bank: the screen, everything the KERNAL
  touches, and the editor's own code and variables. The editor therefore
  loads at `$1300` (2.3 K lower than BASIC's `$1C01`, which is what makes it
  fit) and must end below `$4000` — `petproject_c128.cfg` makes that a link
  error. Today it ends at `$3885`.
- **The buffer is bank 1, `$4000-$BFFF`: 32 K.** The editor runs with bank 1
  mapped (`C128_CFG_EDITOR`, `$4E`) and addresses the buffer natively, as on
  the C64; `work_buf`/`work_buf_end` are constants on this target instead of
  a `.res`. Load and save stream through `CHRIN`/`CHROUT`, which do not care
  which bank the bytes land in.
- **The modules stay in bank 0** at `$9000`/`$A000` and run with bank 0 mapped
  (`C128_CFG_SESSION`, `$0E`); the module call switches banks each way. They
  cannot see the buffer, so every buffer access in a module goes through a
  far-access table the editor keeps in common RAM right after its entry point
  (`FAR_*` in `layout.inc`, `far_api` in `editor.asm`): one `JSR` per byte
  that flips to the bank-1 map, does the one `lda`/`sta (ptr),y`, and flips
  back. The flips are single stores to the MMU's preconfiguration-load
  registers (`$FF01`/`$FF02`), which ignore the value written and leave A and
  the flags alone — so a helper behaves exactly like the instruction it
  replaces, at about 25 cycles instead of 5. In the sources the sites read
  `buf_lda ptr` / `buf_sta ptr`, macros that are the plain instruction on the
  C64 and the call on the C128.

Which sites are buffer accesses was decided per site, not per pointer: a
module's own tables and RAM (modasm's symbol table, modren's mapping table,
modtok's keyword table, modasm's include-file line buffer, all of moddsk)
stay native, since they are in bank 0 with the module. The one pointer that
does both — modasm's `SRC_PTR`, buffer for the main source and module RAM for
include frames — is far only on the buffer path.

Cost: modules that walk the whole buffer byte by byte (tokenize, detokenize,
renumber, search/replace) run their inner loops several times slower on the
C128 than on the C64 — on the order of a second per 32 K of text. The
editor's own rendering and editing are unaffected.

Verified in VICE 3.10 (true-drive 1571): at the idle loop the MMU reads
`$4E`, the preconfiguration registers `$4E`/`$0E`, the RAM configuration
register `$07`, and the gap runs `$4065-$C000` with the demo text at bank-1
`$4000`; Renumber and Disk Utility produce the same screens as before; saving
the demo as BASIC writes a correctly tokenized PRG (modtok, far access) and
loading it back detokenizes it (moddet), with the C64 build producing the
pixel-identical screen for the same key sequence; F7 quits to `READY.`

### Boot sector

`boot128.asm`, linked by `boot128.cfg` into a raw 256-byte image that
`make_disk.py --boot-sector` writes to track 1 sector 0. The KERNAL's boot
routine (BOOT_CALL, `$FF53`, called at the end of BASIC's cold start;
disassembled from the 318020-05 image at `$F890`) reads the sector to `$0B00`,
checks `CBM`, prints `BOOTING` plus the message string, optionally loads a
named file, and then enters the code after the filename through `JSRFAR` in
bank 15 — KERNAL and BASIC ROM in, so the jump table works and an `RTS`
returns to `READY.`

Our sector leaves the filename empty and loads `PETPROJECT128` itself (with
`SETBNK 0,0` and secondary address 1, so the file's own `$1C01` header is
honoured), then jumps to the editor's entry, which sets the session MMU config
first thing. Loading ourselves matters for the other half of the design: since
BASIC's cold start runs the boot sector, the editor's quit path — which ends in
BASIC's cold start — would relaunch the editor. So quit leaves `$51` at `$1BFF`
(`C128_BOOT_FLAG`, in the `$1300-$1BFF` application area nothing else
touches), and the sector checks it _before_ loading: if set, clear it and
`RTS` to `READY.`; otherwise boot. The flag is one-shot, so a reset after
quitting boots normally, and a power cycle randomises it.

### `SETBNK`

C128 KERNAL LOAD/SAVE/OPEN take their data and filename banks from `$C6`/`$C7`,
set via `SETBNK` (`$FF68`). BASIC sets them before each of its own DOS
commands; nothing in the editor session writes them (grep: no `$C6`/`$C7`
stores anywhere), so `c128_init` in `editor.asm` calls `SETBNK` once with both
banks = 0, and the module loader repeats it before its `LOAD` as belt and
braces. `loadsave.asm` and `moddsk` go through `OPEN`/`CHRIN`/`CHROUT`, which
read the same two bytes.

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
- **Keyboard.** `GETIN` is compatible for ordinary keys, and the C128's TAB
  key already emits `$09`, matching `KEY_CTRL_I`. F1-F8 are the exception —
  see [Function keys](#function-keys) below.
- **`$A000–$BFFF` modules get simpler.** That range is plain bank-0 RAM on the
  C128, so the "don't restore `$01` while executing here" hazard
  (`modasm.asm:449`) largely stops being a hazard.
- **Detokenizer tables.** `moddet` already uses an embedded keyword table
  (`moddet.asm:436`) rather than reading BASIC ROM at `$A09E`, so it carries
  no ROM dependency.

---

## Function keys

On the C128 F1-F8 are programmable keys: the screen editor expands each into
its string (`GRAPHIC`, `DLOAD"`, …) before `GETIN` sees anything, so the
`$85-$8C` codes the editor's key dispatch expects never arrive. `c128_init`
rewrites the KERNAL's table at `$1000` (`PKYLEN`, ten lengths) and `$100A`
(`PKYDEF`, the strings) so that each of F1-F8 is a one-byte string holding
the C64 code, and SHIFT-RUN and HELP are empty. The 18 bytes overwritten are
saved and restored on quit, so the user's definitions survive the session.
Verified in VICE: the monitor shows `$1000` = `01 ×8, 00, 00` and `$100A` =
`85 89 86 8A 87 8B 88 8C` at the idle loop, and F8 opens the module menu.

Two related KERNAL details handled at the same time: the key-repeat flag
moved from `$028A` to `$0A22` (`RPTFLG` is target-selected; checked against
the KERNAL image, which references `$0A22` from its repeat logic), and the
program starts by swapping to the 40-column screen if the 80-column one is
active (`MODE` at `$D7`, `SWAPPER` at `$FF5F`).

## Component status

| Component      | C128 effort | Notes                                         |
| -------------- | ----------- | --------------------------------------------- |
| `editor.asm`   | ✅ done     | MMU at entry, `c128_init`, quit via BASIC 7.0 |
| `colorize.asm` | ✅ none     | aliases editor ZP only; moves with it         |
| `loadsave.asm` | ✅ none     | `SETBNK` once at startup covers its `OPEN`s   |
| `modules.asm`  | ✅ done     | banking removed, `SETBNK` before `LOAD`       |
| `modsfr.asm`   | ✅ done     | editor ZP offsets via `layout.inc`            |
| `moddet.asm`   | ✅ done     | ZP scratch equates, header from cfg           |
| `modtok.asm`   | ✅ done     | ZP scratch equates, header from cfg           |
| `modren.asm`   | ✅ done     | ZP scratch + save macro, header from cfg      |
| `moddis.asm`   | ✅ done     | ZP scratch + save macro, header from cfg      |
| `modasm.asm`   | ✅ done     | MMU store, state block rebased to `$9000`     |
| `moddsk.asm`   | ✅ done     | MMU store; `SETBNK` inherited from startup    |
| `modsct.asm`   | **High**    | REU staging at `$B000`; BASIC ABI             |
| `modscr.asm`   | **High**    | BASIC ROM entry points; `$B000` staging       |
| `modscrh.asm`  | **Highest** | 12 BASIC ROM entry points; BASIC 2.0 ZP ABI   |

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
3. **Assert non-overlap at build time** — ✅ **done.** `zp.inc` asserts the
   pool blocks are pairwise disjoint from each other and from
   `ZP_EDITOR`/`ZP_EDITOR_LEN`; `editor.asm` asserts with `lderror` that
   `petproject.cfg` matches those two constants and that the six editor ZP
   symbols `modsfr.asm` borrows are still at their expected offsets. CI
   assembles every C128-eligible module (and links the editor) with
   `-D TARGET_C128` on every change, so the C128 map is exercised too.

   This replaces an earlier plan to make ZP saving universal across all
   modules. That plan was dropped: it guarded against nothing real and would
   have meant editing every exit path in five working modules.

#### Files

| File                  | Role                                                                           |
| --------------------- | ------------------------------------------------------------------------------ |
| `zp.inc`              | target dispatch, derived `ZP_PTR0..3`, contract + assertions, save macros      |
| `zp_c64.inc`          | the historical C64 map — `$3A`, `$F7`, `$FF`                                   |
| `zp_c128.inc`         | the C128 map — `$1C`, `$22`, `$2A`, with the derivation and the residual check |
| `layout.inc`          | per-target load addresses, buffer size and module regions                      |
| `c128.inc`            | MMU, KERNAL entries and variables, boot-flag handshake (C128 only)             |
| `petproject_c128.cfg` | editor at `$1C01`, MAIN capped at `$9000`                                      |
| `module_c128.cfg`     | low modules at `$9000` (was `$C000`)                                           |
| `modsfr_c128.cfg`     | search/replace at `$9000` (was `$C000`)                                        |
| `boot128.asm/.cfg`    | the C128 boot sector (track 1 sector 0 of `petproject.d64`)                    |

Each module now aliases its own local names onto pool slots
(`SRC_PTR = ZP_PTR2`, `TMP = ZP_SCRATCH+0`, …), so module code reads exactly
as before and the diff stays small. Converted: `editor.asm` (the `KW_TOKEN`
alias), `modasm`, `moddet`, `moddis`, `modren`, `moddsk`, `modscrh`,
`modsct`, `modtok`. `modscr` defined a scratch symbol it never used, now
removed. `modsfr` uses no pool scratch, but does borrow editor ZP — see
Tier 1 above. `modscr`, `modscrh` and `modsct` refuse to assemble under
`TARGET_C128` (`.error`): the first two because the C128 map's premise that
BASIC is never called does not hold for them, `modsct` because it exists only
to feed them.

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

**Phase 1 — rehome `$C000`.** ✅ **Done at the link level.** `layout.inc`
carries the per-target addresses; `TARGET=c128 bash make_petproject.sh`
links the editor at `$1C01` under `petproject_c128.cfg` and the low modules at
`$9000` under `module_c128.cfg` / `modsfr_c128.cfg`, with modasm's state block
following `MOD_LO_BASE`. The 225-byte margin is a linker overflow error. See
[The `$C000` collision](#the-c000-collision--the-real-work-in-this-phase) for
the layout and the buffer trade-off. Not yet exercised on hardware.

**Phase 2 — banking.** ✅ **Done.** MMU session config set as the editor's
first instruction and asserted by modasm/moddsk; the loader's `$01` dance
compiled out; `SETBNK` at startup and before module `LOAD`; F-key table,
key-repeat flag and 40-column swap in `c128_init`; quit restores the keys,
banks BASIC ROM in and takes BASIC 7.0's cold start. Trampolines needed no
work (script runner only). Verified in VICE 3.10: the C128 build boots from
`petproject_c128.d64`, shows the editor, opens the module menu on F8, and F7
returns to the BASIC 7.0 banner. Not yet run on hardware.

**Phase 3 — build and packaging.** ✅ **Done.** `make_petproject.sh` builds
both sets by default (`TARGET=all`) and writes one `petproject.d64` carrying
both: the C64 files first, so `LOAD"*",8` on a C64 still gets `PETPROJECT`,
then the C128 set as `PETPROJECT128`, `MODASM128`, … (the suffix is added by
`modules.asm` under `TARGET_C128`, so the C128 editor asks for the right
files). Track 1 sector 0 holds the boot sector from `boot128.asm`, so a C128
autoboots straight into the editor; no runtime machine detection anywhere.
`TARGET=c64` / `TARGET=c128` build one set alone. See
[Boot sector](#boot-sector) for how the sector works and why it has to
cooperate with the quit path. Verified in VICE with a true-drive 1571: reset
boots into the editor, both machines list both sets, F7 returns to `READY.`
without relaunching.

**Phase 4 — the payoff.** In value-per-effort order:

1. **REU-free scripting.** `modscr.asm` stashes `$0801–$9FFF` to REU `$009000`
   purely to make room. Bank 1 does that job, which would remove the one
   hardware requirement in the README. (Gated on the script runner rework.)
2. **Burst mode** with a 1571/1581 — retires the "use a fastloader cartridge"
   advice.
3. **2 MHz bursts** around the assembler's passes, screen blanked, disk I/O
   excluded.
4. **Bigger buffer** via bank 1 — ✅ **done**, 32 K (up from 19.75 K on the
   first C128 layout and 24 K on the C64). See
   [Bank-1 buffer](#bank-1-buffer). The windowing scheme once feared turned
   out to be unnecessary: with the editor in common RAM it addresses bank 1
   natively, and only the modules pay for far access, through a table of
   helpers far cheaper than `INDFET`/`INDSTA`.

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
2. **Trampoline placement — deferred with the script runner.** Only
   `modscr`/`modscrh` use trampolines and neither builds for the C128, so
   nothing in the shipped C128 build needs one. If the script runner is ever
   ported, the analysis stands: an earlier revision suggested page 3, on the
   reasoning that the C128's default bottom common RAM is `$0000–$03FF` so
   anything below `$0400` is visible from every bank. The visibility argument
   holds, but **page 3 is far more crowded on the C128 than on the C64** —
   `$0334-$0349` editor indirect vectors, `$034A-$034D` IRQ keyboard buffer,
   `$0354-$035D` tab-stop bitmaps, `$0362-$0376` file tables, `$0380-$03BF`
   CHRGET, `$03C0-$03FF` bank-relative fetch/poke. Only small gaps remain, and
   the C64's `$033C` cassette buffer does not exist there as free space.

   The likelier answer is the C128 cassette buffer at **`$0B00-$0BFF`** (256
   bytes, free when tape is unused) — but that is outside the default 1 K
   bottom common RAM, so it needs the MMU's RCR (`$D506`) set to a 4 K bottom
   common region (`$0000-$0FFF`) to be bank-visible. Both halves of that need
   confirming: that `$0B00` is genuinely free in our configuration, and the
   RCR setting.

3. ~~**MMU configuration register details**~~ ✅ **Resolved in VICE** — `$0E`
   runs the session (see [Banking](#mmu-configuration-register)); the bit
   table is recorded in `c128.inc`.
4. ~~**Function keys.**~~ ✅ **Resolved** — see [Function keys](#function-keys).
5. ~~**`RPTFLG` at `$028A`**~~ ✅ **Resolved** — `$0A22` on the C128 (`c128.inc`), selected by target in `editor.asm`; the original note read: confirm the address and that
   `$80` still means "all keys repeat" on the C128.
6. ~~**The `$0200–$0222` boot / module parameter block**~~ ✅ **Resolved in
   VICE** — `$0200-$02A1` is BASIC 7.0's input buffer, not the KERNAL's; the
   KERNAL's `CHRIN` from a serial channel does not touch it. `moddsk` lists
   the directory and reads drive status correctly on the C128 build with the
   block in place.
7. ~~**C128 BASIC cold-start entry**~~ ✅ **Resolved** — the quit path restores
   the F-key table, stores `$00` to `$FF00` and jumps to `$4000` (BASIC 7.0
   cold start); VICE shows the BASIC 7.0 banner and `READY.` The reset vector
   was rejected deliberately: a reset re-runs the disk boot sequence, which
   would relaunch the editor once the disk carries a C128 boot sector.
