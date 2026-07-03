# PETProject

**A Commodore 64–native IDE for BASIC and 6502 assembly.**

PETProject is a full-featured integrated development environment that runs
directly on a stock Commodore 64 with a 1541 disk drive. Write, edit, assemble,
disassemble, and renumber code without ever leaving your C64 — no cross-assembler,
no modern PC, no special hardware required.

> 🕹️ **Download a ready-to-run disk image:** <https://gopherbrokesoftware.com/petproject>

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)
![Platform: Commodore 64](https://img.shields.io/badge/platform-Commodore%2064-blue.svg)
![Assembler: cc65](https://img.shields.io/badge/built%20with-cc65-orange.svg)

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Keyboard Reference](#keyboard-reference)
- [Modules](#modules)
- [Building From Source](#building-from-source)
- [Source Layout](#source-layout)
- [Documentation](#documentation)
- [Tips](#tips)
- [License & Credits](#license--credits)

---

## Features

- 🖊️ **Full-screen PETSCII editor** backed by gap-buffer storage (up to ~24 KB of source)
- 🌈 **Syntax highlighting** for both BASIC 2.0 and 6502 assembly
- ⚙️ **Built-in two-pass assembler** — turn your source into runnable machine language
- 🔍 **Built-in disassembler** with full illegal-opcode support; runs automatically when you open an ML file
- 🔢 **Line renumbering** that also fixes `GOTO`/`GOSUB` targets
- 💾 **Disk utility** — browse the directory, load files, delete, rename, format, and send raw drive commands
- 🔎 **Search & replace** with toggleable case sensitivity
- ⌨️ **Keyword completion** — press `TAB` to cycle through completions
- 📜 **BASIC scripting engine** with extended keywords to automate the IDE *(REU required)*
- 🧰 **Many quality-of-life touches** that make coding on a real C64 pleasant
- 📦 **Fully self-contained** — runs perfectly on a stock C64; an REU is optional and used only by the scripting subsystem

---

## Quick Start

1. Grab the disk image (`petproject.d64`) from the
   [download page](https://gopherbrokesoftware.com/petproject), or
   [build it yourself](#building-from-source).
2. Insert it into drive 8 (in [VICE](https://vice-emu.sourceforge.io/) or on real hardware).
3. Load and run:

   ```basic
   LOAD"*",8
   RUN
   ```

   *(Or use your emulator's autostart feature.)*

That's it — you're in the editor. Press `F8` to open the module picker, or start
typing to write some BASIC.

> 💡 **Tip:** Your experience will be much smoother with a fastloader cartridge.

---

## Keyboard Reference

| Key | Action |
| --- | --- |
| `F1` | Settings — colors, data-drive number, cursor blink |
| `F2` | Page Up |
| `F3` | Load a file (BASIC, assembly, or compiled ML) |
| `F4` | Page Down |
| `F5` | Save the current file |
| `F6` | Load a SEQ (plain text / source) file |
| `F7` | Quit to BASIC |
| `F8` | Open the module picker (see [Modules](#modules)) |
| `CTRL+F` | Find / replace |
| `CTRL+L` | Force a full screen redraw |
| `CTRL+N` | New file (clears the buffer) |
| `CTRL+R` | Run Script (shortcut for `F8 → Run Script`) |
| `TAB` | Cycle keyword completions |
| Cursor keys | Navigate |
| `INST/DEL` | Delete the character left of the cursor |

> ℹ️ The **program disk must stay in drive 8**; the data drive is configurable in
> Settings (`F1`). If you try to do something destructive (new file, load, quit)
> with unsaved changes, the IDE prompts you to save first. During long-running
> tasks it flashes the top-left character so you know it's working, not frozen.

---

## Modules

Reach these from the module picker (`F8`):

| Module | Purpose |
| --- | --- |
| **Assemble** (MODASM) | Two-pass 6502 assembler — compiles the current buffer to ML |
| **Disassemble** (MODDIS) | 6502 disassembler; runs automatically when loading an ML file |
| **Renumber** (MODREN) | Renumbers BASIC lines and updates `GOTO`/`GOSUB` targets |
| **Disk Utility** (MODDSK) | Directory browser, delete, rename, format, raw commands |
| **Run Script** (MODSCT/MODSCR/MODSCRH) | Run BASIC automation scripts with extended keywords *(REU required)* |

Search & replace (MODSFR) is available directly via `CTRL+F`.

---

## Building From Source

**Requirements:** the [cc65](https://cc65.github.io/) toolchain (`ca65` + `ld65`,
v2.19 or newer) and Python 3.

```bash
# Build the editor, all modules, and the .d64 disk image
bash make_petproject.sh
```

To build only the modules:

```bash
bash build_modules.sh
```

To (re)create the disk image manually:

```bash
python3 make_disk.py --build-dir build --name petproject --id pp petproject.d64
```

> ⚠️ `make_petproject.sh` ends with an optional line that launches VICE
> (`x64sc`). Edit or comment out that path to match your setup. See the script's
> comments for the full `ca65`/`ld65` invocations, which you can override with the
> `CA65` and `LD65` environment variables.

---

## Source Layout

**Editor core**

| File | Description |
| --- | --- |
| `editor.asm` | Main editor: entry point, main loop, rendering, input |
| `colorize.asm` | Syntax colorizer (included by `editor.asm`) |
| `loadsave.asm` | File I/O (included by `editor.asm`) |
| `modules.asm` | Module-loader framework (included by `editor.asm`) |
| `petproject.cfg` | Linker config for the editor PRG |

**Modules**

| File | Loads at | Description |
| --- | --- | --- |
| `modasm.asm` | `$A000` | Assembler |
| `moddis.asm` | `$A000` | Disassembler |
| `modren.asm` | `$C000` | Renumber |
| `moddsk.asm` | `$C000` | Disk utility |
| `modsfr.asm` | `$C000` | Search / replace |
| `moddet.asm` | — | Detokenizer (hidden; runs on BASIC load) |
| `modtok.asm` | — | Tokenizer (hidden; runs on BASIC save) |
| `modsct.asm` | — | Script tokenizer (hidden; runs on Run Script) |
| `modscr.asm` | `$A000` | Script runner stub |
| `modscrh.asm` | `$C000` | Script handler (stays resident during scripts) |

**Linker configs:** `module.cfg` (default `$C000`), `modasm.cfg` (`$A000`),
`moddis.cfg`, `modsfr.cfg`, `modscr.cfg`, `modsct.cfg`.

**Build tooling:** `make_petproject.sh` (full build), `build_modules.sh`
(modules only), `make_disk.py` (creates the `.d64` image).

**Reference:** `Resources/basic.asm` and `Resources/kernal.asm` are annotated
ROM disassemblies kept for reference.

---

## Documentation

In-depth manuals live in the [`docs/`](docs/) directory:

- [Editor manual](docs/editor_manual.md)
- [Assembler manual](docs/assembler_manual.md)
- [Renumber manual](docs/renumber_manual.md)
- [Script runner manual](docs/script-runner-manual.md)

Security policy: [`SECURITY.md`](SECURITY.md).

---

## Tips

- Use a **fastloader cartridge** for a much snappier experience.
- Keep the **program disk in drive 8**; point Settings (`F1`) at a separate data
  drive if you have one.
- The scripting engine needs an **REU** for script tokenization and IDE snapshots.

---

## License & Credits

Released under the **MIT License** — see [`LICENSE.txt`](LICENSE.txt).

PETProject was designed and built by **Thomas Knox / Gopher Broke Software**.
