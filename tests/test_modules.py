#!/usr/bin/env python3
"""End-to-end tests for the buffer-rewriting modules.

Runs the real assembled C64 modules (build/*.prg) on an emulated 6502
(py65) against an in-memory gap buffer, exactly as the editor calls them:
parameter block at $0212, editor gap pointers in zero page $02-$05.

Covers MODTOK/MODDET (tokenize + detokenize round trip, REM/DATA literals,
overflow restore) and MODREN (ON...GOTO lists, a split gap, the in-place
overtake guard).

Usage:
    bash make_petproject.sh      # produces build/*.prg
    python3 tests/test_modules.py

Requires: pip install py65
"""

import sys
from pathlib import Path

from py65.devices.mpu6502 import MPU

REPO = Path(__file__).resolve().parent.parent
BUILD = REPO / "build"

BUF = 0x3000
BUF_END = 0x9000  # 24 K, like the C64 editor's buffer
RETURN_TO = 0xCFF0  # sentinel return address for the module's RTS
GETIN = 0xFFE4


def run_module(name, pre, post=b"", buf_end=BUF_END, max_steps=50_000_000):
    """Run module `name` on the gap buffer [pre | gap | post].

    Returns (status, linear output or None, memory).
    """
    prg = (BUILD / f"{name}.prg").read_bytes()
    load = prg[0] | (prg[1] << 8)
    m = MPU()
    mem = m.memory
    mem[load : load + len(prg) - 2] = list(prg[2:])

    gs = BUF + len(pre)
    ge = buf_end - len(post)
    mem[BUF:gs] = list(pre)
    mem[ge:buf_end] = list(post)

    def w16(addr, val):
        mem[addr] = val & 0xFF
        mem[addr + 1] = val >> 8

    mem[0x0212] = 0x4D  # MOD_MAGIC
    mem[0x0213] = 0  # MOD_COMMAND
    mem[0x021C] = 8  # MOD_DRIVE
    mem[0x021D] = 0  # MOD_DIALECT
    mem[0x021E] = 0xFF  # MOD_STATUS
    w16(0x0214, BUF)
    w16(0x0216, gs)
    w16(0x0218, ge)
    w16(0x021A, buf_end)
    w16(0x02, gs)  # editor GAP_START
    w16(0x04, ge)  # editor GAP_END

    # Kernal: every entry is an RTS; GETIN returns "no key".
    for a in range(0xE000, 0x10000):
        mem[a] = 0x60
    mem[GETIN : GETIN + 3] = [0xA9, 0x00, 0x60]

    m.sp = 0xFF
    m.stPush((RETURN_TO - 1) >> 8)
    m.stPush((RETURN_TO - 1) & 0xFF)
    m.pc = load
    for _ in range(max_steps):
        if m.pc == RETURN_TO:
            break
        m.step()
    else:
        raise AssertionError(f"{name}: runaway at ${m.pc:04x}")

    status = mem[0x021E]
    if status != 0x02:
        return status, None, mem
    new_end = mem[0x021F] | (mem[0x0220] << 8)
    return status, bytes(mem[BUF:new_end]), mem


def check(cond, what):
    assert cond, what
    print(f"ok: {what}")


def test_tokenize_round_trip():
    cases = [
        # graphics and shifted letters after REM stay literal
        b'10 REM \xc0\xc0\xa0 HI \xc1\xc2\r20 PRINT"\xc1":GOTO10\r',
        # DATA literal up to an unquoted ':'; a quoted ':' doesn't end it
        b'10 DATA A\xc1B,"X:Y",\xc0:PRINT"\xc1"\r20 X=1:DATA \xb0\xc5\r30 END\r',
        b'10 FORI=1TO9:NEXT\r20 ?"HI";:REM\r',
    ]
    for src in cases:
        st, tok, _ = run_module("modtok", src)
        assert st == 0x02, f"modtok status ${st:02x} for {src!r}"
        st, back, _ = run_module("moddet", tok)
        assert st == 0x02, f"moddet status ${st:02x}"
        expected = src.replace(b"?", b"PRINT")
        assert back == expected, f"round trip:\n  {src!r}\n  {back!r}"
    print("ok: tokenize/detokenize round trip (REM, DATA, strings, ?)")


def test_tokenize_overflow_restores_text():
    src = b"".join(b'%d A$="XYZ"\r' % i for i in range(10, 400, 10))
    end = BUF + len(src) + 30  # too little room for text + output
    st, _, mem = run_module("modtok", src, buf_end=end)
    check(
        st == 0x01 and bytes(mem[BUF : BUF + len(src)]) == src,
        "modtok overflow fails and restores the text exactly",
    )


KEYWORDS = [
    "END",
    "FOR",
    "NEXT",
    "DATA",
    "INPUT#",
    "INPUT",
    "DIM",
    "READ",
    "LET",
    "GOTO",
    "RUN",
    "IF",
    "RESTORE",
    "GOSUB",
    "RETURN",
    "REM",
    "STOP",
    "ON",
    "WAIT",
    "LOAD",
    "SAVE",
    "VERIFY",
    "DEF",
    "POKE",
    "PRINT#",
    "PRINT",
    "CONT",
    "LIST",
    "CLR",
    "CMD",
    "SYS",
    "OPEN",
    "CLOSE",
    "GET",
    "NEW",
    "TAB(",
    "TO",
    "FN",
    "SPC(",
    "THEN",
    "NOT",
    "STEP",
    "+",
    "-",
    "*",
    "/",
    "^",
    "AND",
    "OR",
    ">",
    "=",
    "<",
    "SGN",
    "INT",
    "ABS",
    "USR",
    "FRE",
    "POS",
    "SQR",
    "RND",
    "LOG",
    "EXP",
    "COS",
    "SIN",
    "TAN",
    "ATN",
    "PEEK",
    "LEN",
    "STR$",
    "VAL",
    "ASC",
    "CHR$",
    "LEFT$",
    "RIGHT$",
    "MID$",
    "GO",
    "ASSEMBLE",
    "INCLUDE",
    "RUNPROG",
    "SCRATCH",
    "DELETE",
    "EXISTS",
    "RENAME",
    "STATUS",
    "DRIVE",
    "ONERR",
    "PAUSE",
    "COPY",
    "DIR",
]


def body(out):
    """The token bytes of a one-line program: drop header, link, line no."""
    return out[6:-3]


def test_every_keyword():
    # tokens $80-$D8 in order; each keyword alone on a line
    for tok, kw in enumerate(KEYWORDS, 0x80):
        src = b"10 " + kw.encode() + b"\r"
        st, out, _ = run_module("modtok", src)
        assert st == 0x02 and body(out) == bytes([tok]), f"{kw}: {out!r}"
        st, back, _ = run_module("moddet", out)
        assert st == 0x02 and back == src, f"{kw}: {back!r}"
    print("ok: every keyword tokenizes to its token and back")


def test_shifted_abbreviations():
    # A shifted letter ends an abbreviation; the first entry in the
    # longest-first table that it fits wins (G<shift-O> is GOSUB, not GOTO).
    src = b"10 G\xcf20:P\xd2A:L\xc9:F\xcfI:NE\xd8:S\xd4:R\xc5\r"
    st, out, _ = run_module("modtok", src)
    want = b"\x8d20:\x98A:\x9b:\x81I:\x82:\xd3:\x8c"
    check(st == 0x02 and body(out) == want, "shifted-letter abbreviations")
    # A shifted letter EQUAL to a keyword's final char is not an
    # abbreviation (F<shift-N> is not FN): the match runs on past the entry.
    st, out, _ = run_module("modtok", b"10 PRINTF\xce(1)\r")
    check(st == 0x02 and body(out) == b"\x99F\xce(1)", "F<shift-N> stays literal")


def test_tokenize_page_boundaries():
    # the relocation/restore copies go a page at a time: lengths around
    # page multiples, with and without room for the output
    line = b'10 PRINT"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":GOTO10\r'
    for n in (1, 255, 256, 257, 512, 513):
        src = (line * (n // len(line) + 1))[:n]
        st, out, _ = run_module("modtok", src)
        assert st == 0x02, f"len {n}: status ${st:02x}"
        st, back, _ = run_module("moddet", out)
        assert st == 0x02, f"len {n}: moddet status ${st:02x}"
        # the cut-off last line has no CR, so compare by re-tokenizing
        st, again, _ = run_module("modtok", back)
        assert again == out, f"len {n}: re-tokenize differs"
        end = BUF + n + 3
        st, _, mem = run_module("modtok", src, buf_end=end)
        assert st == 0x01 and bytes(mem[BUF : BUF + n]) == src, f"len {n}: restore"
    print("ok: tokenize/restore across page boundaries")


def test_renumber():
    src = b"5 ON X GOTO 7, 9 ,5\r7 GOSUB 9\r9 IF A THEN 5\r"
    expected = b"10 ON X GOTO 20, 30 ,10\r20 GOSUB 30\r30 IF A THEN 10\r"
    st, out, _ = run_module("modren", src)
    check(st == 0x02 and out == expected, "renumber: ON...GOTO list, GOSUB, THEN")
    st, out, _ = run_module("modren", src[:12], src[12:])
    check(st == 0x02 and out == expected, "renumber: cursor mid-buffer (split gap)")


def test_renumber_overtake_guard():
    lines = b"".join(b"%d GOTO %d\r" % (i, i) for i in range(1, 400))
    pre, post = lines[: len(lines) // 2], lines[len(lines) // 2 :]
    end = BUF + len(lines) + 40  # numbers grow by far more than 40 bytes
    st, _, mem = run_module("modren", pre, post, buf_end=end)
    gs, ge = BUF + len(pre), end - len(post)
    intact = bytes(mem[BUF:gs]) == pre and bytes(mem[ge:end]) == post
    check(st == 0x01 and intact, "renumber: overtake refused, buffer unchanged")
    st, out, _ = run_module("modren", pre, post)
    expected = b"".join(b"%d GOTO %d\r" % (i * 10, i * 10) for i in range(1, 400))
    check(st == 0x02 and out == expected, "renumber: 399 lines with room to grow")


def main():
    for name in ("modtok", "moddet", "modren"):
        if not (BUILD / f"{name}.prg").exists():
            sys.exit(f"build/{name}.prg not found — run: bash make_petproject.sh")
    test_tokenize_round_trip()
    test_tokenize_overflow_restores_text()
    test_every_keyword()
    test_shifted_abbreviations()
    test_tokenize_page_boundaries()
    test_renumber()
    test_renumber_overtake_guard()
    print("\nall module tests passed")


if __name__ == "__main__":
    main()
