# PETProject Script Runner — Usage Manual

The script runner lets you write a BASIC program in the editor, augmented with
a set of extended disk and control keywords, and run it on a live C64 with an
REU attached. This document covers how to run a script, how the extended
keywords work, and the current limitations.

> **Requirement:** the script runner needs an REU (RAM Expansion Unit). It uses
> the REU to stash the IDE out of the way, deploy your tokenized script to
> `$0801`, and hand control to BASIC. Without an REU the runner reports an
> error and aborts.

---

## Running a script

1. Type your program in the editor, one BASIC line per line, with line numbers
   (e.g. `10 DRIVE 8`).
2. Press **F8** to open the MODULES popup.
3. Choose **5. RUN SCRIPT**.

OR

Press **CTRL-R** in the editor to immediately run the script.

What happens under the hood: three modules load and run in sequence —
**MODSCT** tokenizes the editor buffer (plus any includes) into the REU,
**MODSCRH** installs the extended-keyword handlers at `$C000`, and **MODSCR**
stashes the IDE into the REU, deploys the tokenized program to `$0801`, patches
BASIC's vectors, and runs it. When the program ends (or errors), the IDE is
restored from the REU and you are returned to the editor.

The screen will flicker as the IDE is swapped out, your program runs, and the
IDE is swapped back in. For a fast script this can be nearly instantaneous.

---

## Writing scripts: what to know

**Standard BASIC works normally.** `PRINT`, `FOR`/`NEXT`, `IF`/`THEN`, `GOTO`,
`POKE`, etc. all run under the stock C64 BASIC interpreter, because the runner
hands your program to BASIC's normal statement executor. Type them as you
always would.

**Extended keywords are dispatched before BASIC sees them.** The runner hooks
BASIC's `IGONE` vector. At the start of each statement it checks whether the
current token is one of the extended keywords (`$CC`–`$D8`). If so, it runs the
matching handler; otherwise it passes the statement to BASIC unchanged.

**Numeric arguments are single bytes (0–255), except `ONERR`.** `DRIVE` and
`PAUSE` read their numeric argument with BASIC's GETBYT routine, so values
above 255 will not work as expected. `ONERR` takes a full 16-bit line number.

**String arguments are quoted.** Disk-name keywords expect a quoted string,
e.g. `DELETE "OLDFILE"`. Two-name keywords use `TO` between the names, e.g.
`RENAME "OLD" TO "NEW"`. A missing or malformed argument raises a real
`?SYNTAX ERROR`, which `ONERR` can catch like any other error.

**Logical files 2 and 15 are used transiently** by `STATUS`, `DIR`, `EXISTS`,
`RENAME`, `COPY`, `DELETE`, `SCRATCH`, and `ASSEMBLE`. Don't keep your own
files open on LA 2 or 15 across those statements.

---

## Extended keyword reference

The runner defines 13 extended keywords in the token range `$CC`–`$D8`.

#### `DRIVE n`

Sets the current drive (device number) used by subsequent disk operations in
the script. Defaults to **8** if never set.

```basic
10 DRIVE 8
20 DELETE "TEMP"
```

Range 0–255 (realistically 8–11 for IEC devices).

#### `PAUSE n`

Waits _n_ jiffies (1 jiffy = 1/60 second on NTSC, 1/50 on PAL), then continues.
Uses the jiffy clock at `$A2`. `PAUSE 0` does nothing.

```basic
10 PRINT "READY"
20 PAUSE 60
30 PRINT "ONE SECOND LATER"
```

#### `STATUS`

Opens the current drive's command channel, reads the drive status string, and
**prints it** (followed by a newline). Use it to check the result of a disk
operation or just to confirm the drive is responding.

```basic
10 DRIVE 8
20 DELETE "TEMP"
30 STATUS
```

A healthy result looks like `00, OK,00,00`; an error like `62, FILE NOT
FOUND,00,00`. The string is printed at the current cursor position, exactly as
the drive returns it.

#### `RUNPROG "file"`

Loads another BASIC program from the current drive and runs it, replacing the
current script (a "chain"). The loaded program runs from its first line, **and
it also gets the extended keywords** — so a chained program can itself use
`DRIVE`, `PAUSE`, `STATUS`, `RUNPROG`, and the rest. When the chained program
ends, you are returned to the IDE as usual.

```basic
10 PRINT "STAGE 1 DONE"
20 RUNPROG "STAGE2"
```

Notes and caveats:

- The program is loaded to the BASIC start (`$0801`) and run from line 1.
  Variables from the current script are **not** preserved across the chain
  (RUNPROG performs a CLR, like `RUN`).
- If the file cannot be loaded (not found, drive error), the script ends and
  you are returned to the IDE.
- Because this replaces the running program, any statements after `RUNPROG` on
  the same line — or on later lines — are **not** executed. Treat `RUNPROG` as
  the last thing a program does.

#### `DELETE "filename"`

Sends a scratch command (`S0:filename`) to the current drive's command channel,
deleting the named file.

```basic
10 DRIVE 8
20 DELETE "OLDDATA"
30 STATUS
```

#### `SCRATCH "pattern"`

Identical mechanism to `DELETE`, but intended for wildcard patterns (the CBM DOS
`S:` command accepts `*` and `?`).

```basic
10 SCRATCH "TEMP*"
```

#### `ONERR line`

Registers a line number to jump to when a BASIC runtime error occurs. When any
error fires (including a syntax error in an extended keyword, or an `ASSEMBLE`
failure), execution branches to the registered line instead of ending the
script. `ONERR 0` (or never calling it) restores the default behavior: the
script ends and the IDE is restored.

```basic
10 ONERR 100
20 DELETE "NOSUCHFILE"
30 STATUS
40 END
100 PRINT "ERROR TRAPPED"
110 END
```

The handler does not reset after firing — if the error line itself errors, you
can loop. Keep error handlers simple.

#### `DIR`

Displays the directory of the current `DRIVE`, with block counts, exactly like
`LOAD "$",8` / `LIST` but without disturbing your program.

```basic
10 DRIVE 8
20 DIR
30 PAUSE 120
40 END
```

#### `RENAME "old" TO "new"`

Renames a file on the current drive (DOS `R0:new=old`). Check `STATUS`
afterwards for the drive's verdict (e.g. `63, FILE EXISTS` if the target name
is taken).

```basic
10 RENAME "DRAFT" TO "FINAL"
20 STATUS
```

#### `COPY "src" TO "dst"`

Copies a file on the current drive (DOS `C0:dst=src`). Same-drive only — CBM
DOS has no inter-drive copy on single-drive units.

```basic
10 COPY "DATA" TO "DATA.BAK"
20 STATUS
```

#### `EXISTS "file"`

Tests whether the named file exists on the current drive and stores the result
in the BASIC numeric variable **`EX`**: `1` if the file exists, `0` if not.
The variable is created if it doesn't exist yet.

```basic
10 EXISTS "CONFIG"
20 IF EX=0 THEN PRINT "NO CONFIG": END
30 PRINT "CONFIG FOUND"
```

A file is considered to exist if the drive reports `00, OK` or `64, FILE TYPE
MISMATCH` (present, but a different type) when probed; `62, FILE NOT FOUND`
means it doesn't.

#### `INCLUDE "file"`

> ⚠️ **Not yet supported.** `INCLUDE` is reserved for a future release.
> MODSCT recognizes the keyword but stops tokenization with an
> `INCLUDE UNSUPPORTED` error rather than importing the file. (In earlier
> builds the half-finished include pipeline could corrupt the running IDE —
> failing loudly is the safe interim behavior.) Keep each script in a single
> file for now.

#### `ASSEMBLE "source" TO "output"`

Runs the MODASM assembler on a source file from inside a running script, then
**continues the script** — variables, program text, and position all survive.

```basic
10 DRIVE 8
20 ONERR 100
30 DELETE "DEMO"
40 ASSEMBLE "DEMO.S" TO "DEMO"
50 PRINT "BUILD OK"
60 END
100 PRINT "BUILD FAILED"
110 END
```

How it works (and why it's safe): MODASM needs `$C000`–`$CFFF` for its symbol
table and `$0801`–`$9FFF` for the source text — both regions a running script
depends on. `ASSEMBLE` therefore stashes the script-runner handler to REU
`$013000` and the entire script RAM to REU `$014000`, loads the source into
the vacated space, loads MODASM (from **device 8**, where the PETProject
modules live) to `$A000`, and runs it via a small trampoline in the cassette
buffer. When the assembler finishes, both regions are restored byte-identically
from the REU and the script resumes at the next statement.

Notes and caveats:

- **The source file is read from the current `DRIVE`**; MODASM itself always
  loads from device 8. The **output PRG is written to the current `DRIVE`**.
- Source files saved by the PETProject editor (PRG-typed raw text) and genuine
  SEQ files both work — the loader retries with `,S,R` automatically.
- **The output file must not already exist.** MODASM writes with a bare name,
  so an existing file produces `63, FILE EXISTS`. `DELETE` the output first
  (as in the example above).
- Maximum source size after includes: `$0801`–`$9FFF` (just under 38 KB).
- On assembly failure, the script prints `?ASSEMBLE ERROR IN LINE n` (the
  **source** line number) and raises an error. With `ONERR` set, your handler
  runs immediately; without it, the message is held on screen for two seconds
  before the IDE returns (so the repaint doesn't eat it).
- `ASSEMBLE`'s `INCLUDE` directives inside the source are handled by MODASM
  itself, depth-limited, same as an interactive assemble.

---

## A complete example

```basic
10 DRIVE 8
20 ONERR 200
30 PRINT "BUILDING..."
40 EXISTS "DEMO"
50 IF EX=1 THEN DELETE "DEMO"
60 ASSEMBLE "DEMO.S" TO "DEMO"
70 PRINT "OK - BACKING UP SOURCE"
80 COPY "DEMO.S" TO "DEMO.BAK"
90 STATUS
100 RUNPROG "DEMO"
200 PRINT "BUILD FAILED"
210 END
```

A self-contained build script: trap errors, remove the stale binary only if it
exists, assemble, back up the source, then chain into the freshly built
program.

---

## Limitations summary

- **REU required** — no REU, no script runner. `ASSEMBLE` additionally claims
  REU `$013000`–`$013FFF` and `$014000`–`$01D7FE` while it runs.
- All 13 extended keywords are functional.
- `RUNPROG` chains (replaces the current program); variables are not carried
  over.
- Numeric arguments are limited to **0–255**, except `ONERR`'s line number.
- A BASIC error without `ONERR` set (or normal program end) returns you to the
  editor. Note: without `ONERR`, errors are currently **silent** — the script
  simply ends and the IDE comes back. Use `ONERR` (or check `STATUS`) if you
  need to know something failed.
- `COPY` is same-drive only.
- `EXISTS` always writes to the variable named `EX`.
- Don't hold logical files 2 or 15 open across extended disk keywords.

---

## Token reference (for the curious)

The extended keywords occupy BASIC tokens `$CC`–`$D8`:

| Token | Keyword  | Token | Keyword |
| ----- | -------- | ----- | ------- |
| `$CC` | ASSEMBLE | `$D3` | STATUS  |
| `$CD` | INCLUDE  | `$D4` | DRIVE   |
| `$CE` | RUNPROG  | `$D5` | ONERR   |
| `$CF` | SCRATCH  | `$D6` | PAUSE   |
| `$D0` | DELETE   | `$D7` | COPY    |
| `$D1` | EXISTS   | `$D8` | DIR     |
| `$D2` | RENAME   |       |         |

In the editor buffer these are stored as plain PETSCII text; they are tokenized
when the script is run and detokenized back to text when a tokenized program is
loaded. `ASSEMBLE ... TO ...` and the `RENAME`/`COPY` forms use BASIC's own
`TO` token (`$A4`) between the names, so the tokenizer needs no special cases.
