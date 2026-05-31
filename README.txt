PETProject v0.1 — A C64-native BASIC and 6502 assembly IDE
===========================================================

Download the IDE from https://gopherbrokesoftware.com/petproject

PETProject is an integrated development environment that runs directly on
a stock Commodore 64 with a 1541 disk drive.  No special hardware is
required (REU optional, used only for the BASIC scripting subsystem).

FEATURES
  - Full-screen PETSCII editor with gap-buffer storage
  - Syntax highlighting for BASIC 2.0
  - Load / save plain text and tokenized BASIC files
  - F8 module picker: Assemble, Disassemble, Renumber, Disk Utility
  - Inline 6502 two-pass assembler (MODASM)
  - 6502 disassembler (MODDIS)
  - BASIC line renumber (MODREN)
  - Disk utility — directory browser, delete, rename, format (MODDSK)
  - Search and replace (MODSFR, CTRL+F)
  - BASIC scripting engine with extended keywords (MODSCT/MODSCR/MODSCRH)
    (requires REU for script tokenization and IDE snapshot)

BUILDING
  Requirements: ca65 and ld65 (cc65 toolchain)

  1. Build the editor and all modules:
       bash make_petproject.sh
     or, to build modules only:
       bash build_modules.sh

  2. Create the .d64 disk image:
       python3 make_disk.py --build-dir build --name petproject --id pp petproject.d64

  See make_petproject.sh for the full ca65/ld65 invocations.

SOURCE LAYOUT
  editor.asm      Main editor (entry point, main loop, rendering, input)
  colorize.asm    Syntax colorizer (included by editor.asm)
  loadsave.asm    File I/O (included by editor.asm)
  modules.asm     Module loader framework (included by editor.asm)
  petproject.cfg  Linker config for the editor PRG

  modasm.asm      Assembler module (loads at $A000)
  moddis.asm      Disassembler module (loads at $A000)
  modren.asm      Renumber module (loads at $C000)
  moddsk.asm      Disk utility module (loads at $C000)
  modsfr.asm      Search/replace module (loads at $C000)
  moddet.asm      Detokenizer module — hidden, called on BASIC file load
  modtok.asm      Tokenizer module — hidden, called on BASIC file save
  modsct.asm      Script tokenizer — hidden, called by Run Script
  modscr.asm      Script runner stub (loads at $A000)
  modscrh.asm     Script handler (loads at $C000, stays resident during script)
  module.cfg      Default linker config for $C000 modules
  modasm.cfg      Linker config for $A000 modules (modasm, moddis, modscr)
  moddis.cfg      Linker config for moddis (same start, smaller CODE region)
  modsfr.cfg      Linker config for modsfr (extended, includes BSS)
  modscr.cfg      Linker config alias for modscr
  modsct.cfg      Linker config alias for modsct

  make_disk.py    Python script to create the .d64 disk image
  make_petproject.sh  Full build script (edit paths before use)
  build_modules.sh    Build all modules only

  Resources/      C64 ROM images (BASIC 901226-01, Kernal 901227-03,
                  Character ROM 901225-01) — used only for reference
                  (moddet.asm reads ROM at runtime; no ROM data compiled in)

USAGE
  Boot from the .d64 image in VICE or on real hardware:
    LOAD"*",8,1   (or use the autostart feature of your emulator)

  Editor keys:
    F1            Settings (colors, drive number)
    F3            Load file
    F5            Save file
    F7            Quit to BASIC
    F8            Module picker (Assemble / Disassemble / Renumber / Disk Utility / Run Script)
    CTRL+F        Search and replace
    CTRL+R        Run script (shortcut for F8 > Run Script)
    CTRL+N        New file (clear buffer)
    CTRL+L        Force full screen redraw
    Cursor keys   Navigate
    INST/DEL      Delete character left of cursor

LICENSE
  MIT License — see LICENSE.txt

CREDITS
  PETProject was designed and built by Tom Knox / Gopher Broke Software.
  Architecture discussions with Greg Nacu (C64OS) and Dennis (VisionBASIC).
