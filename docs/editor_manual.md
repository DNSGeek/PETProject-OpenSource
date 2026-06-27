# C64 IDE

## Features

- Supports BASIC and Assembly
- Full syntax highlighting for both BASIC and assembly
- Built in assembler
- Auto-disassembly if opening machine language files
- Line renumbering, including GOTO and GOSUB targets
- Disk browser: View directory, format disks, open files, send raw commands
- Built in search/replace with toggleable case sensitivity
- Up to 24KB of space for source code
- Many small quality of life enhancements to make writing code on a C64 nicer
- Fully self contained, does not depend on anything else. Runs perfectly on a stock C64.

## Usage

### Special Keys

- F1: Open the settings popup.
  - Change the colors
  - Change the drive to use for data. The program disk always needs to be in drive 8.
  - Toggle cursor blinking on or off.
- F2: Page Up - Go up an entire page of source code
- F3: Load - Load a file; BASIC, Assembly or compiled ML
- F4: Page Down - Go down an entire page of source code
- F5: Save - Save the current file
- F6: Load SEQ (source code/text) files
- F7: Quit
- F8: Open the modules chooser
  - Assemble: Assemble the current file into ML
  - Disassemble: Normally not needed to be invoked manually, will be run automatically if the IDE detects you're loading a compiled ML file.
  - Renumber: Renumbers your source code
  - Disk Utility: Browse the data disk
  - Run Script: Write automations scripts in BASIC with some extended keywords and run them.
- CTRL-F: Find. Open the find/replace module
- CTRL-L: Redraw the screen
- CTRL-N: New file. Clears out the editor and starts fresh
- CTRL-R: Shortcut for Run Script
- TAB: Complete the keyword. Pressing TAB will cycle through all of the completions.

If you attempt to do something destructive (new file, load file, quit) with unsaved changes, you will be prompted if you want to save first.

On long running tasks, the IDE will flash the top left character to let you know that it's working and not crashed.

## PLEASE NOTE:

Your experience will be much improved if you use a fastloader cartridge with this software.

To use just run LOAD"\*",8 and then RUN.
