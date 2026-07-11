# PETProject Assembler — User Manual

> **Module:** MODASM  
> **Accessed via:** F8 → Assemble

---

## Table of Contents

1. [What Is an Assembler?](#1-what-is-an-assembler)
2. [Getting Started](#2-getting-started)
3. [Source Line Format](#3-source-line-format)
4. [Comments](#4-comments)
5. [Labels](#5-labels)
6. [Numbers and Values](#6-numbers-and-values)
7. [Expressions](#7-expressions)
8. [Directives](#8-directives)
9. [Addressing Modes](#9-addressing-modes)
10. [Instruction Reference](#10-instruction-reference)
11. [Error Messages](#11-error-messages)
12. [Limits and Constraints](#12-limits-and-constraints)
13. [A Complete Example](#13-a-complete-example)

---

## 1. What Is an Assembler?

The 6502 processor inside your Commodore 64 only understands raw numbers — bytes of machine code. Writing those numbers by hand is tedious and error-prone. **Assembly language** lets you write those same instructions using short, readable names instead:

| Machine code  | Assembly    |
| ------------- | ----------- |
| `$A9 $01`     | `LDA #1`    |
| `$8D $20 $D0` | `STA $D020` |
| `$60`         | `RTS`       |

The **assembler** is the program that translates your assembly source text into those raw bytes and saves them as a `.PRG` file you can load and run.

PETProject's assembler supports the complete standard 6502 instruction set. It is a **two-pass assembler**: it reads your source twice. On the first pass it collects all your label names and their addresses; on the second pass it uses those addresses to emit the correct machine code. This means you can freely refer to a label before you define it.

---

## 2. Getting Started

1. Type your assembly source into the PETProject editor as normal text.
2. Press **F8** to open the module picker, then select **Assemble**.
3. The status bar will prompt you for an output filename. Type a name (up to 16 characters) and press **RETURN**. Press **RUN/STOP** to cancel.
4. The assembler runs. On success, the output `.PRG` file is written to disk and the status bar shows `OK`.
5. On error, the status bar shows a red error message and the line number where the problem was found.

The output file is a standard Commodore PRG file with a 2-byte load address header. By default the load address is **$0801** (the start of BASIC RAM), which you can change with `.org` (see [Directives](#8-directives)).

---

## 3. Source Line Format

Each line of your source file follows this pattern:

```
[label:]  MNEMONIC  [operand]  [;comment]
```

Every part is optional except that you need _something_ on a line for it to do anything. Blank lines and lines containing only a comment are fine and are skipped.

- **Label** — a name ending with a colon, written at the start of the line.
- **Mnemonic** — the 3-letter instruction name, or a directive beginning with `.`.
- **Operand** — what the instruction acts on (a number, address, or expression).
- **Comment** — anything after a `;` is ignored.

Both uppercase and lowercase letters are accepted everywhere. Labels and mnemonics are internally converted to uppercase, so `lda`, `LDA`, and `Lda` are all the same.

**Examples of valid lines:**

```
        LDA #0          ; load 0 into A
loop:   STA $0400,Y     ; store A to screen, Y offset
        DEY             ; decrement Y
        BNE loop        ; loop until Y wraps to 0
        RTS             ; return
```

---

## 4. Comments

A semicolon (`;`) begins a comment. Everything from the `;` to the end of the line is ignored by the assembler. Comments can appear on their own line or after an instruction.

```
; This whole line is a comment.
        CLC     ; this part is a comment
```

---

## 5. Labels

A **label** is a name that represents an address in your program. You define a label by writing its name followed immediately by a colon:

```
start:  LDA #$00
```

You can then use that name anywhere an address is expected:

```
        BNE start
        JMP start
        LDA #<start     ; lo byte of start's address
```

### Label Rules

- Labels can be up to **8 characters** long. Characters beyond 8 are ignored.
- Valid characters are: letters (`A`–`Z`, `a`–`z`), digits (`0`–`9`), and underscore (`_`).
- Labels are **case-insensitive**: `Loop`, `LOOP`, and `loop` all refer to the same label.
- The colon (`:`) must immediately follow the name — no space before it.
- Labels on their own line (with no instruction following) are perfectly valid, and the label simply points to the next instruction that follows.
- You can refer to a label **before** you define it. The two-pass design handles forward references.
- A label may only be **defined once**. Defining the same name twice is an error.

**Valid label names:** `loop`, `start`, `irq_handler`, `MY_DATA`, `v1`, `loop2`

**Invalid label names:** `my label` (space), `2fast` (starts with digit), `toolonglabel` (over 8 chars — will be silently truncated to `toolongla`)

---

## 6. Numbers and Values

The assembler understands two number formats.

### Hexadecimal (Base 16)

Write a dollar sign `$` followed by hex digits (`0`–`9`, `A`–`F`). This is the most common format for addresses and hardware registers on the C64, because memory addresses map neatly to hex.

```
        LDA #$FF        ; immediate value 255
        STA $D020       ; address of border colour register
        LDA $C0         ; zero page address $C0
```

Hex digits may be uppercase or lowercase: `$ff` and `$FF` are the same.

### Decimal (Base 10)

Write plain digits with no prefix. Useful for counts, loop indices, and small constants.

```
        LDX #10         ; load 10 into X
        CPY #100        ; compare Y to 100
```

### How Size Is Determined

The assembler decides whether to use a **zero page** (1-byte address) or **absolute** (2-byte address) instruction based on the size of the value you write:

- If the value fits in one byte (`$00`–`$FF` or `0`–`255`), zero page mode is tried first.
- If the value needs two bytes (`$0100` and above), absolute mode is used.
- If the instruction has no zero page form, absolute mode is used automatically.

You don't need to do anything special — it just works.

---

## 7. Expressions

Operand values can be more than just plain numbers. The assembler supports several expression forms.

### Label References

Use a label name directly as a value. Its address is substituted automatically.

```
        JMP main        ; jump to address of 'main'
```

### Offset Arithmetic

Add or subtract a **literal number** from a label's address (or another value). The offset must be a plain number, not another label.

```
table:  .byte 1, 2, 3, 4, 5

        LDA table+2     ; loads the byte at table's address + 2 (value = 3)
        LDA table+4     ; loads the byte at table's address + 4 (value = 5)
```

### Lo and Hi Byte Extraction

When a 16-bit address needs to be split into its two component bytes (common when setting up 16-bit pointers), use `<` for the low byte and `>` for the high byte.

```
        LDA #<target    ; low byte of target's address
        STA $FB
        LDA #>target    ; high byte of target's address
        STA $FC
```

These can be combined with offsets:

```
        LDA #<(table+10)    ; lo byte of table+10
```

---

## 8. Directives

Directives are assembler commands that don't produce machine code instructions directly. They control the assembly process or emit raw data. Directives begin with a period (`.`), and the alternative `*=` form is also supported for setting the origin.

---

### `.org` — Set the Program Counter

Tells the assembler that the code that follows should start at a specific address. This determines the **load address** of the output PRG file. Use it once, at the very start of your source.

```
        .org $C000      ; code will load at $C000
```

**Alternative form** — `*=` does the same thing:

```
        *= $C000
```

If you don't use `.org` or `*=`, the default load address is **$0801** (the start of the BASIC area).

You can also use `.org` mid-source to skip ahead in memory (for example, to place data at a known fixed address), but this will leave a gap of uninitialised bytes in the output file. Usually it is simpler to just define your data at a convenient offset from your code.

---

### `.byte` — Emit Raw Bytes

Embeds one or more raw bytes directly into the output at the current position. Values must fit in the range 0–255 (`$00`–`$FF`). Multiple values are separated by commas.

```
my_data:
        .byte $01, $02, $03
        .byte 65, 66, 67            ; decimal: ASCII 'A', 'B', 'C'
        .byte $FF                   ; single byte
```

Labels in `.byte` lists are allowed and their low byte is used:

```
        .byte <some_label
```

---

### `.word` — Emit 16-Bit Words

Embeds one or more 16-bit values in **little-endian** order (low byte first, then high byte), as the 6502 expects. Common use: jump tables, address vectors, and BASIC stub line links.

```
vectors:
        .word irq_handler           ; emits lo byte then hi byte of address
        .word nmi_handler
        .word $0801                 ; emits $01 then $08
```

---

### `.text` — Emit a String

Embeds a string of characters as raw PETSCII bytes. The string must be enclosed in double quotes. No escape sequences are supported — type what you want.

```
message:
        .text "HELLO, WORLD!"
        .byte $00                   ; add a NUL terminator if needed
```

The characters are stored as-is. What you type is in PETSCII, so uppercase letters in the editor will appear as uppercase on screen. Note: `.text` does _not_ add any length byte or terminator automatically — add one with `.byte` if your code needs it.

---

### `.include` – Import another assembly file into the current file

Reads another source file from disk and assembles its lines as if they were
typed at the position of the directive. The filename must be enclosed in
double quotes and can be up to 16 characters. The file is read from the same
drive the assembler writes its output to.

```
        .include "macros.asm"       ; assemble MACROS.ASM here
        JSR CLRSCR                  ; labels defined there are visible
```

Details worth knowing:

- **Labels are shared.** Everything defined in an included file goes into the
  same symbol table, so the main file can reference labels from the include
  and vice versa (forward references work as usual).
- **Nesting** is allowed up to 7 levels deep; an 8th level stops assembly
  with `INCLUDE TOO DEEP`.
- **Anything after the closing quote is ignored** — the rest of the line is
  treated as a comment. Put code for the directive's line in the included
  file instead.
- **Line numbers in error messages are per-file.** An error on the second
  line of an included file is reported as line 2, not as a position in the
  main source. (The editor's jump-to-error will still move within the main
  buffer, so open the included file to fix it.)
- **Files are read twice**, once per assembly pass, so assembling from a
  1541 is naturally slower with many includes.
- A missing or unreadable file stops assembly with `I/O ERROR` on the
  `.include` line. Included files saved by the editor work as-is; a SEQ
  file created by another tool can be pulled in by appending the DOS type
  suffix inside the quotes, e.g. `.include "helpers,s"` (the suffix counts
  toward the 16 characters).
- Source lines in included files can be up to 80 characters; longer lines
  stop assembly with `LINE TOO LONG`.

---

## 9. Addressing Modes

Addressing modes describe _where_ an instruction gets its data or sends its result. Not every instruction supports every mode — the assembler will report an error if you try an unsupported combination.

### Implied (No Operand)

The instruction acts on a fixed, built-in target. No operand is written.

```
        CLC             ; clear carry flag
        RTS             ; return from subroutine
        INX             ; increment X register
        NOP             ; do nothing
```

### Accumulator

The instruction operates on the accumulator register. Write `A` as the operand.

```
        ASL A           ; shift accumulator left
        LSR A           ; shift accumulator right
        ROL A           ; rotate accumulator left
        ROR A           ; rotate accumulator right
```

### Immediate (`#`)

The operand is a **literal value** — the actual number, not an address. Prefix the value with `#`.

```
        LDA #$42        ; load the value $42 into A
        LDA #65         ; load the value 65 (decimal) into A
        LDA #<label     ; load the low byte of label's address into A
        CPX #10         ; compare X to the number 10
```

### Zero Page

The operand is an address in the first 256 bytes of memory (`$00`–`$FF`). Zero page instructions are 1 byte shorter and faster than absolute instructions. If your value fits in one byte, zero page is chosen automatically.

```
        LDA $80         ; load from address $0080
        STX $FB         ; store X at address $00FB
```

### Zero Page,X and Zero Page,Y

Add the X or Y register to a zero page address. The result wraps around within the zero page (if the sum exceeds `$FF` it wraps to the start of the zero page, it does not carry into page 1).

```
        LDA $80,X       ; load from $80 + X
        STX $80,Y       ; store X at $80 + Y  (only LDX/STX support ,Y in ZP)
```

### Absolute

The operand is a full 16-bit address. Used when the address is outside the zero page or when the instruction has no zero page form.

```
        LDA $1000       ; load from address $1000
        STA $D020       ; store to $D020 (border colour)
        JMP $C000       ; jump to $C000
```

### Absolute,X and Absolute,Y

Add the X or Y register to a 16-bit address. Used to step through arrays and tables.

```
        LDA $C000,X     ; load from $C000 + X
        STA $0400,Y     ; store A to screen RAM + Y
```

### Indirect (`(addr)`)

Only used with `JMP`. The operand is the address of a 2-byte little-endian pointer; the processor reads that pointer and jumps to it. Useful for dispatch tables.

```
        JMP ($FFFE)     ; jump to the address stored at $FFFE/$FFFF
        JMP (vec_ptr)   ; jump to address stored at label vec_ptr
```

> **Classic 6502 Bug:** If the pointer address falls on a page boundary (e.g. `$C0FF`), the processor reads the high byte from `$C000` instead of `$C100`. Avoid placing indirect jump vectors at `$xxFF` addresses.

### Indexed Indirect — `(addr,X)` — also called "(zp,X)"

Add X to a zero page address to get a pointer address, then read the 2-byte pointer from that zero page location and use it as the target. X selects _which pointer_ in a table of zero page pointers.

```
        LDA ($70,X)     ; read pointer at $70+X and load from that address
```

### Indirect Indexed — `(addr),Y` — also called "(zp),Y"

Read a 2-byte pointer from a zero page address, then add Y to that pointer to get the final address. Y selects _which byte_ within the block the pointer addresses. This is the standard way to index into a block of data when you have its base address in the zero page.

```
        STA ($FB),Y     ; store A to address-at-$FB plus Y
```

### Relative (Branch Instructions)

Used exclusively by the eight branch instructions (`BCC`, `BCS`, `BEQ`, `BMI`, `BNE`, `BPL`, `BVC`, `BVS`). You write a label as the target and the assembler calculates the signed byte offset automatically.

```
@loop:  DEX
        BNE @loop       ; branch back to @loop if X ≠ 0
```

> **Range Limit:** Branches can only reach targets within **−128 to +127 bytes** of the instruction following the branch. If your target is too far away, you will get a `BAD ADDR MODE` error. The fix is to branch to a nearby `JMP` instruction that jumps to the real target.

---

## 10. Instruction Reference

All 56 standard 6502 instructions are supported. The table below shows each instruction, a brief description, and which addressing modes are available.

**Mode key:**
`IMP` = Implied · `ACC` = Accumulator · `IMM` = Immediate · `ZP` = Zero Page ·
`ZPX` = Zero Page,X · `ZPY` = Zero Page,Y · `ABS` = Absolute · `ABX` = Absolute,X ·
`ABY` = Absolute,Y · `IND` = Indirect · `IZX` = (Indirect,X) · `IZY` = (Indirect),Y ·
`REL` = Relative (branch offset)

---

### Load and Store

| Mnemonic | Description       | Supported Modes                       |
| -------- | ----------------- | ------------------------------------- |
| `LDA`    | Load Accumulator  | IMM, ZP, ZPX, ABS, ABX, ABY, IZX, IZY |
| `LDX`    | Load X Register   | IMM, ZP, ZPY, ABS, ABY                |
| `LDY`    | Load Y Register   | IMM, ZP, ZPX, ABS, ABX                |
| `STA`    | Store Accumulator | ZP, ZPX, ABS, ABX, ABY, IZX, IZY      |
| `STX`    | Store X Register  | ZP, ZPY, ABS                          |
| `STY`    | Store Y Register  | ZP, ZPX, ABS                          |

### Register Transfers

| Mnemonic | Description                 | Mode |
| -------- | --------------------------- | ---- |
| `TAX`    | Transfer A to X             | IMP  |
| `TAY`    | Transfer A to Y             | IMP  |
| `TXA`    | Transfer X to A             | IMP  |
| `TYA`    | Transfer Y to A             | IMP  |
| `TSX`    | Transfer Stack Pointer to X | IMP  |
| `TXS`    | Transfer X to Stack Pointer | IMP  |

### Stack

| Mnemonic | Description                     | Mode |
| -------- | ------------------------------- | ---- |
| `PHA`    | Push Accumulator onto stack     | IMP  |
| `PHP`    | Push Processor flags onto stack | IMP  |
| `PLA`    | Pull Accumulator from stack     | IMP  |
| `PLP`    | Pull Processor flags from stack | IMP  |

### Arithmetic

| Mnemonic | Description                  | Supported Modes                       |
| -------- | ---------------------------- | ------------------------------------- |
| `ADC`    | Add with Carry               | IMM, ZP, ZPX, ABS, ABX, ABY, IZX, IZY |
| `SBC`    | Subtract with Borrow (Carry) | IMM, ZP, ZPX, ABS, ABX, ABY, IZX, IZY |

> Always `CLC` before `ADC` and `SEC` before `SBC` unless you specifically need the carry from a previous operation.

### Increment and Decrement

| Mnemonic | Description      | Supported Modes   |
| -------- | ---------------- | ----------------- |
| `INC`    | Increment memory | ZP, ZPX, ABS, ABX |
| `DEC`    | Decrement memory | ZP, ZPX, ABS, ABX |
| `INX`    | Increment X      | IMP               |
| `INY`    | Increment Y      | IMP               |
| `DEX`    | Decrement X      | IMP               |
| `DEY`    | Decrement Y      | IMP               |

### Logical

| Mnemonic | Description                           | Supported Modes                       |
| -------- | ------------------------------------- | ------------------------------------- |
| `AND`    | Bitwise AND with Accumulator          | IMM, ZP, ZPX, ABS, ABX, ABY, IZX, IZY |
| `ORA`    | Bitwise OR with Accumulator           | IMM, ZP, ZPX, ABS, ABX, ABY, IZX, IZY |
| `EOR`    | Bitwise Exclusive-OR with Accumulator | IMM, ZP, ZPX, ABS, ABX, ABY, IZX, IZY |

### Shift and Rotate

| Mnemonic | Description                  | Supported Modes        |
| -------- | ---------------------------- | ---------------------- |
| `ASL`    | Arithmetic Shift Left        | ACC, ZP, ZPX, ABS, ABX |
| `LSR`    | Logical Shift Right          | ACC, ZP, ZPX, ABS, ABX |
| `ROL`    | Rotate Left (through carry)  | ACC, ZP, ZPX, ABS, ABX |
| `ROR`    | Rotate Right (through carry) | ACC, ZP, ZPX, ABS, ABX |

### Compare and Test

| Mnemonic | Description         | Supported Modes                       |
| -------- | ------------------- | ------------------------------------- |
| `CMP`    | Compare Accumulator | IMM, ZP, ZPX, ABS, ABX, ABY, IZX, IZY |
| `CPX`    | Compare X Register  | IMM, ZP, ABS                          |
| `CPY`    | Compare Y Register  | IMM, ZP, ABS                          |
| `BIT`    | Bit Test            | ZP, ABS                               |

### Branches

All branches use REL mode. Write a label as the target.

| Mnemonic | Description              | Branches if…      |
| -------- | ------------------------ | ----------------- |
| `BCC`    | Branch if Carry Clear    | Carry flag = 0    |
| `BCS`    | Branch if Carry Set      | Carry flag = 1    |
| `BEQ`    | Branch if Equal (zero)   | Zero flag = 1     |
| `BNE`    | Branch if Not Equal      | Zero flag = 0     |
| `BMI`    | Branch if Minus          | Negative flag = 1 |
| `BPL`    | Branch if Plus           | Negative flag = 0 |
| `BVC`    | Branch if Overflow Clear | Overflow flag = 0 |
| `BVS`    | Branch if Overflow Set   | Overflow flag = 1 |

### Jumps and Calls

| Mnemonic | Description                | Supported Modes |
| -------- | -------------------------- | --------------- |
| `JMP`    | Jump                       | ABS, IND        |
| `JSR`    | Jump to Subroutine         | ABS             |
| `RTS`    | Return from Subroutine     | IMP             |
| `RTI`    | Return from Interrupt      | IMP             |
| `BRK`    | Software Break / Interrupt | IMP             |

### Flags

| Mnemonic | Description             | Mode |
| -------- | ----------------------- | ---- |
| `CLC`    | Clear Carry             | IMP  |
| `SEC`    | Set Carry               | IMP  |
| `CLI`    | Clear Interrupt Disable | IMP  |
| `SEI`    | Set Interrupt Disable   | IMP  |
| `CLD`    | Clear Decimal Mode      | IMP  |
| `SED`    | Set Decimal Mode        | IMP  |
| `CLV`    | Clear Overflow          | IMP  |

### Miscellaneous

| Mnemonic | Description                                 | Mode |
| -------- | ------------------------------------------- | ---- |
| `NOP`    | No Operation (does nothing, takes 2 cycles) | IMP  |

---

## 11. Error Messages

When an error occurs, assembly stops at the first error found. The status bar shows a red message and the line number. Fix the problem and reassemble.

| Message         | Meaning                                                                                                     |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| `SYNTAX ERROR`  | The line couldn't be parsed — check for typos, missing colons, or bad `*=` syntax.                          |
| `VALUE ERROR`   | A number or expression couldn't be evaluated — invalid hex digits, empty expression, etc.                   |
| `SYMBOL ERROR`  | A label was defined more than once, or the symbol table is full (see [Limits](#12-limits-and-constraints)). |
| `BAD MNEMONIC`  | The 3-letter instruction name couldn't be read — check your spelling and spacing.                           |
| `UNKNWN OP`     | The mnemonic is not a known 6502 instruction.                                                               |
| `BAD OPERAND`   | The operand syntax is wrong — mismatched parentheses, missing `X`/`Y`, etc.                                 |
| `BAD ADDR MODE` | The instruction doesn't support the addressing mode you used, or a branch target is out of range.           |
| `I/O ERROR`     | A disk problem — the output file couldn't be written (disk full, write-protected), or an included file is missing or unreadable. |
| `INCLUDE TOO DEEP` | `.include` files are nested more than 7 levels deep.                                                     |
| `LINE TOO LONG` | A line in an included file is longer than 80 characters.                                                    |

---

## 12. Limits and Constraints

| Item                      | Limit                                                             |
| ------------------------- | ----------------------------------------------------------------- |
| Label name length         | 8 characters (extra characters are silently ignored)              |
| Total labels              | 400                                                               |
| Output filename length    | 16 characters                                                     |
| `.include` filename       | 16 characters (including any DOS type suffix)                     |
| `.include` nesting depth  | 7 levels                                                          |
| Line length in includes   | 80 characters                                                     |
| Branch range              | ±127 bytes from the instruction after the branch                  |
| String content in `.text` | No escape sequences; no embedded double quotes                    |
| Expression arithmetic     | Addition and subtraction of a single numeric offset only          |
| Expression nesting        | `<` and `>` apply to a single base expression; no complex nesting |
| Integer size              | 16-bit unsigned values (`$0000`–`$FFFF`)                          |
| Source encoding           | PETSCII (the C64's native character set)                          |

---

## 13. A Complete Example

Here is a small but complete program that draws a coloured bar across the top row of the C64 screen.

```
; ============================================================
; colourbar.asm
; Fills the top row of screen RAM ($0400) with '@' (screen
; code $00) and sets the colour of each cell to light blue.
; ============================================================

        .org $0801          ; standard BASIC load address

; BASIC stub: SYS 2062 (calls our code at $080E)
        .word $080B         ; link to next BASIC line
        .word 2024          ; BASIC line number
        .byte $9E           ; BASIC token: SYS
        .text "2062"        ; argument: address of 'main' in decimal
        .byte $00           ; end of BASIC line
        .word $0000         ; end of BASIC program

; ----------------------------------------------------------
main:
        ldx #39             ; 40 columns, index 0-39
@loop:
        lda #$20            ; screen code for space (cleared cell)
        sta $0400,x         ; write to screen RAM
        lda #14             ; colour 14 = light blue
        sta $D800,x         ; write to colour RAM
        dex
        bpl @loop           ; loop until X goes negative (below 0)

        rts                 ; return to BASIC
```

### What this does, line by line

- `.org $0801` — tells the assembler the program loads at $0801, the standard start of BASIC RAM. The PRG file header will contain $01 $08.
- The `.word` and `.byte`/`.text` directives lay down a 10-byte BASIC stub that makes BASIC automatically run the machine code via `SYS 2062` when you `RUN` the program.
- `LDX #39` — loads 39 into X. We'll use X as a countdown from 39 to 0, covering all 40 screen columns.
- `LDA #$20` / `STA $0400,X` — puts a space character into screen RAM at column X of row 0.
- `LDA #14` / `STA $D800,X` — sets the colour of that cell to light blue.
- `DEX` / `BPL @loop` — decrement X and loop back while the result is positive or zero (N flag clear). When X becomes −1 (wraps to 255), the N flag sets and the branch is not taken.
- `RTS` — returns to BASIC.

### Assembling and running it

1. Type or paste the source into PETProject.
2. Press **F8**, choose **Assemble**.
3. Enter a filename, e.g. `COLOURBAR`, and press **RETURN**.
4. Load and run: `LOAD "COLOURBAR",8` then `RUN`.
