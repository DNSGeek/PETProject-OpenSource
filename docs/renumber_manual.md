# PETProject — Line Renumbering Guide

PETProject has two complementary features for managing BASIC line numbers:
**auto-numbering** as you type, and the **MODREN** renumber tool with `LINENO`
directives for banding subroutines into high number ranges.

---

## 1. Auto-numbering on RETURN

When you press RETURN at the **end** of a numbered BASIC line, the editor adds
the next line number automatically, followed by a space, so you can keep typing.

```
10 PRINT "HI"        ← type this, press RETURN
20                   ← editor adds "20 " for you
```

### How the next number is chosen

The editor looks at the current line's number (N) and the following line's
number (M), if any:

- **No line follows** → N + 10.
- **Plenty of room** (gap to next line greater than 10, including large gaps
  like 40 → 10000) → N + 10.
- **Tight spacing** (gap of 2–10) → halfway between, i.e. N + gap/2. So pressing
  RETURN on line 10 when line 20 is next gives **15**.
- **No room** (consecutive numbers, e.g. 40 and 41) → a plain newline with no
  number. Renumber (below) to open up space.

### When it does NOT fire

- In **assembly** source (auto-numbering is BASIC-only).
- When RETURN is pressed in the **middle** of a line to split it — you get a
  plain newline, no injected number.
- On a **blank or unnumbered** line — plain newline.
- If the computed number would reach **64000 or higher** (the CBM BASIC limit is 63999) — plain newline.

### Removing an unwanted number

The inserted number is ordinary text. If you don't want it, just backspace over
it like anything else.

---

## 2. MODREN — full renumber

MODREN rewrites every line number in the program to a clean sequence and fixes
all the references that point at them (`GOTO`, `GOSUB`, `THEN`, `ON…GOTO`, etc.).

Run it from the **F8 module popup** and select RENUMBER.

By default it numbers from **10** in steps of **10**: the first line becomes 10,
the next 20, and so on. References are updated to match, so a `GOSUB 100` still
points at the same routine after its line number changes.

After a renumber the cursor lands at the end of the listing. Use **F2 / F4**
(page up / page down) or **CTRL-F** (find) to move around.

---

## 3. `LINENO` directives — banding subroutines

A plain renumber packs everything into one tight sequence, which jams your
subroutines right up against the end of the main code. To keep subroutines in
their own high number ranges, drop a `LINENO` directive in a REM:

```
REM LINENO <base> [<step>]
```

When MODREN reaches this line, it sets the line numbering to start at `<base>`
(and, optionally, to count in `<step>` increments) from that point onward. The
REM line itself becomes `<base>`, and the lines after it count up from there.

### Example

Source before renumber:

```
10 PRINT "MAIN"
20 GOSUB 200
30 GOSUB 300
40 END
200 REM LINENO 10000 50
210 PRINT "BLOCK A"
220 RETURN
300 REM LINENO 20000
310 PRINT "BLOCK B"
320 RETURN
```

After renumber:

```
10 PRINT "MAIN"
20 GOSUB 10000          ← reference updated to the new base
30 GOSUB 20000          ← reference updated
40 END
10000 REM LINENO 10000 50
10050 PRINT "BLOCK A"   ← step 50, as specified
10100 RETURN
20000 REM LINENO 20000
20010 PRINT "BLOCK B"   ← step reverts to default 10
20020 RETURN
```

Main code stays at 10, 20, 30, 40. The first subroutine lives at 10000+ in steps
of 50; the second at 20000+ in the default steps of 10.

### Rules and notes

- **Syntax is exact:** `REM LINENO <base>`, optionally a step after the base.
  A REM that doesn't match this form (e.g. `REM LINE 100`, `REM LINENOX 5`, or a
  `REM LINENO` with no number) is treated as an ordinary comment and renumbered
  normally.
- **Step is per-directive.** If a directive omits the step, the step **resets to
  the default of 10** — it does not carry over from an earlier directive. State
  one explicitly on every directive that needs a non-default step.
- **The directive line keeps its REM** in the output, so the banding is
  self-documenting and survives future renumbers.
- **Maximum line number is 63999.** A base or sequence that would reach 64000
  aborts the renumber (the buffer is left unchanged).
- **You are responsible for ordering.** Nothing stops you from setting a base
  that is lower than the block above it (e.g. `REM LINENO 50` after the program
  has already passed 50), which produces out-of-order or duplicate numbers. Keep
  each band's base above the previous block's highest line.

### A note on spacing

Choose a `step` that leaves room for the lines you'll add later. A sparse,
high-numbered subroutine block often wants a coarser step (50 or 100) so you can
insert lines without an immediate re-renumber. The auto-numberer's halfway logic
will keep finding gaps as long as there's room between consecutive lines.
