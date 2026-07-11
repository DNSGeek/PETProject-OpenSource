#!/usr/bin/env python3
"""End-to-end tests for MODASM's .include directive.

Runs the real assembled module (build/modasm.prg) on an emulated 6502
(py65), with the Kernal channel-I/O entry points stubbed by a fake IEC
drive that mimics the 1541 behaviors the assembler depends on:

  * the final byte of a file arrives TOGETHER with the EOF status (EOI);
  * reading a drained channel again raises a read-timeout status;
  * any OPEN/CLOSE/CHKIN bus command drops an active LISTEN, so issuing
    one while the output file's channel is selected is a bug (the fake
    drive asserts on it instead of corrupting output like real hardware).

Usage:
    bash build_modules.sh        # produces build/modasm.prg
    python3 tests/test_include.py

Requires: pip install py65
"""

import sys
from pathlib import Path

from py65.devices.mpu6502 import MPU

REPO = Path(__file__).resolve().parent.parent
PRG = REPO / "build" / "modasm.prg"

# ---- Kernal entry points (must match modasm.asm) ----
SETLFS, SETNAM, OPEN, CLOSE = 0xFFBA, 0xFFBD, 0xFFC0, 0xFFC3
CHKIN, CHKOUT, CLRCHN = 0xFFC6, 0xFFC9, 0xFFCC
CHRIN, CHROUT, READST, GETIN = 0xFFCF, 0xFFD2, 0xFFB7, 0xFFE4

# ---- modasm.asm interface addresses ----
MOD_COMMAND = 0x0213
MOD_BUF = 0x0214          # lo/hi
MOD_GAP_START = 0x0216
MOD_GAP_END = 0x0218
MOD_BUF_END = 0x021A
MOD_DRIVE = 0x021C
MOD_STATUS = 0x021E
BATCH_FNAME_LEN = 0x02C0
BATCH_FNAME = 0x02C1
ASM_ERR_LINE_LO = 0xC008
ASM_ERR_MSG = 0xC00A
SRC_DEPTH = 0xBF00

BUF_START = 0x3000
RETURN_TO = 0xCFFF        # sentinel return address for the module's RTS


def sc_decode(codes):
    """Decode a zero-terminated screen-code string (error messages)."""
    out = []
    for c in codes:
        if c == 0:
            break
        if 1 <= c <= 26:
            out.append(chr(ord("A") + c - 1))
        elif c == 0x20:
            out.append(" ")
        elif c == 0x2F:
            out.append("/")
        else:
            out.append("?")
    return "".join(out)


class FakeDrive:
    """Minimal IEC drive + Kernal channel-table emulation."""

    def __init__(self, files):
        self.files = dict(files)      # name -> bytes (disk contents)
        self.open_files = {}          # lfn -> dict
        self.st = 0                   # Kernal status byte ($90)
        self.dflt_in = None           # CHKIN-selected LFN
        self.dflt_out = None          # CHKOUT-selected LFN
        self.screen = bytearray()     # CHROUT with no output channel
        self.pend_lfn = self.pend_dev = self.pend_sa = 0
        self.pend_name = ""
        self.bus_violations = []

    def _bus_command(self, what):
        # OPEN/CLOSE/CHKIN all put commands on the serial bus under ATN,
        # ending in UNLISTEN — which silently drops an active LISTEN.
        # Real hardware would then lose subsequent CHROUT bytes; we
        # record it as a violation so tests fail loudly.
        if self.dflt_out is not None:
            self.bus_violations.append(
                f"{what} issued while output channel {self.dflt_out} active"
            )

    # ---- Kernal API ----
    def setlfs(self, a, x, y):
        self.pend_lfn, self.pend_dev, self.pend_sa = a, x, y

    def setnam(self, length, addr, mem):
        self.pend_name = bytes(mem[addr:addr + length]).decode("latin1")

    def open(self):
        self._bus_command("OPEN")
        self.st = 0
        if self.pend_lfn in self.open_files:
            return 2  # FILE OPEN error, C=1
        entry = {
            "name": self.pend_name,
            "sa": self.pend_sa,
            "pos": 0,
            "missing": False,
            "data": None,
        }
        if self.pend_sa == 1:  # write channel
            entry["data"] = bytearray()
        else:  # read channel: serial OPEN succeeds even if file is absent
            if self.pend_name in self.files:
                entry["data"] = self.files[self.pend_name]
            else:
                entry["missing"] = True
        self.open_files[self.pend_lfn] = entry
        return None  # success, C=0

    def close(self, lfn):
        self._bus_command("CLOSE")
        f = self.open_files.pop(lfn, None)
        if f is not None and f["sa"] == 1:
            self.files[f["name"]] = bytes(f["data"])
        if self.dflt_in == lfn:
            self.dflt_in = None
        if self.dflt_out == lfn:
            self.dflt_out = None

    def chkin(self, lfn):
        self._bus_command("CHKIN")
        if lfn not in self.open_files:
            return 3  # FILE NOT OPEN, C=1
        self.dflt_in = lfn
        self.st = 0
        return None

    def chkout(self, lfn):
        if lfn not in self.open_files:
            return 3
        self.dflt_out = lfn
        self.st = 0
        return None

    def clrchn(self):
        self.dflt_in = None
        self.dflt_out = None

    def chrin(self):
        if self.dflt_in is None:
            raise AssertionError("CHRIN with no input channel selected")
        f = self.open_files[self.dflt_in]
        if f["missing"]:
            self.st |= 0x02       # read timeout: drive has nothing to say
            return 0x0D
        data, pos = f["data"], f["pos"]
        if pos < len(data):
            f["pos"] += 1
            # EOI: EOF status arrives WITH the final byte
            self.st = 0x40 if f["pos"] == len(data) else 0
            return data[pos]
        if len(data) == 0:
            # empty file: drive pads with a single CR + EOI
            self.st = 0x40
            return 0x0D
        # reading past EOI-terminated data: timeout on real hardware
        self.st |= 0x42
        return 0x0D

    def chrout(self, byte):
        if self.dflt_out is None:
            self.screen.append(byte)
            return
        f = self.open_files[self.dflt_out]
        if f["sa"] != 1:
            raise AssertionError("CHROUT to a read channel")
        f["data"].append(byte)


class Machine:
    def __init__(self, source, files):
        self.mpu = MPU()
        self.mem = self.mpu.memory
        self.drive = FakeDrive(files)

        prg = PRG.read_bytes()
        load = prg[0] | (prg[1] << 8)
        assert load == 0xA000, f"unexpected load address ${load:04x}"
        self.mem[load:load + len(prg) - 2] = list(prg[2:])

        src = source.replace("\n", "\r").encode("latin1")
        end = BUF_START + len(src)
        self.mem[BUF_START:end] = list(src)
        self._w16(MOD_BUF, BUF_START)
        self._w16(MOD_GAP_START, end)   # zero-width gap at buffer end
        self._w16(MOD_GAP_END, end)
        self._w16(MOD_BUF_END, end)
        self.mem[MOD_DRIVE] = 8
        self.mem[MOD_STATUS] = 0xFF
        self.mem[MOD_COMMAND] = 0x01    # batch: no keyboard prompt
        name = b"OUT"
        self.mem[BATCH_FNAME_LEN] = len(name)
        self.mem[BATCH_FNAME:BATCH_FNAME + len(name)] = list(name)

    def _w16(self, addr, val):
        self.mem[addr] = val & 0xFF
        self.mem[addr + 1] = (val >> 8) & 0xFF

    def _stub_rts(self):
        m = self.mpu
        lo = self.mem[0x100 + ((m.sp + 1) & 0xFF)]
        hi = self.mem[0x100 + ((m.sp + 2) & 0xFF)]
        m.sp = (m.sp + 2) & 0xFF
        m.pc = (((hi << 8) | lo) + 1) & 0xFFFF

    def _set_carry(self, err):
        if err is None:
            self.mpu.p &= ~self.mpu.CARRY
        else:
            self.mpu.p |= self.mpu.CARRY
            self.mpu.a = err

    def run(self, max_steps=20_000_000):
        m, d = self.mpu, self.drive
        # fake JSR $A000 from RETURN_TO-1
        ret = RETURN_TO - 1
        m.sp = 0xFD
        self.mem[0x1FE] = ret & 0xFF
        self.mem[0x1FF] = ret >> 8
        m.pc = 0xA000
        for _ in range(max_steps):
            pc = m.pc
            if pc == RETURN_TO:
                return
            if pc == SETLFS:
                d.setlfs(m.a, m.x, m.y); self._stub_rts()
            elif pc == SETNAM:
                d.setnam(m.a, m.x | (m.y << 8), self.mem); self._stub_rts()
            elif pc == OPEN:
                self._set_carry(d.open()); self._stub_rts()
            elif pc == CLOSE:
                d.close(m.a); self._set_carry(None); self._stub_rts()
            elif pc == CHKIN:
                self._set_carry(d.chkin(m.x)); self._stub_rts()
            elif pc == CHKOUT:
                self._set_carry(d.chkout(m.x)); self._stub_rts()
            elif pc == CLRCHN:
                d.clrchn(); self._stub_rts()
            elif pc == CHRIN:
                m.a = d.chrin(); self._stub_rts()
            elif pc == CHROUT:
                d.chrout(m.a); self._stub_rts()
            elif pc == READST:
                m.a = d.st; self._stub_rts()
            elif pc == GETIN:
                raise AssertionError("GETIN called in batch mode")
            else:
                m.step()
        raise AssertionError("execution did not finish (runaway loop?)")

    # ---- result accessors ----
    @property
    def status(self):
        return self.mem[MOD_STATUS]

    @property
    def output(self):
        return self.drive.files.get("OUT")

    @property
    def err_msg(self):
        return sc_decode(self.mem[ASM_ERR_MSG:ASM_ERR_MSG + 20])

    @property
    def err_line(self):
        return self.mem[ASM_ERR_LINE_LO] | (self.mem[ASM_ERR_LINE_LO + 1] << 8)

    def check_clean_finish(self):
        assert not self.drive.bus_violations, self.drive.bus_violations
        assert not self.drive.screen, (
            f"{len(self.drive.screen)} output bytes leaked to the screen"
        )
        for lfn, f in self.drive.open_files.items():
            raise AssertionError(f"LFN {lfn} ({f['name']}) left open")
        assert self.mem[SRC_DEPTH] == 0, "source frame stack not empty"


def assemble(source, files=None):
    m = Machine(source, files or {})
    m.run()
    m.check_clean_finish()
    return m


def flatten(source, files):
    """Reference expansion of .include for equivalence checks."""
    out = []
    for line in source.split("\n"):
        s = line.strip().upper()
        if s.startswith(".INC"):
            name = line.split('"')[1]
            text = files[name].decode("latin1").replace("\r", "\n")
            out.append(flatten(text.rstrip("\n"), files))
        else:
            out.append(line)
    return "\n".join(out)


def expect_output(m, expected, what):
    assert m.status == 0, f"{what}: status={m.status} err={m.err_msg!r}"
    got = m.output
    assert got == expected, (
        f"{what}: output mismatch\n  got:      {got.hex(' ') if got else got}"
        f"\n  expected: {expected.hex(' ')}"
    )


def expect_error(m, msg, what, line=None):
    assert m.status == 1, f"{what}: expected error, got status={m.status}"
    assert m.err_msg == msg, f"{what}: err={m.err_msg!r}, expected {msg!r}"
    if line is not None:
        assert m.err_line == line, f"{what}: err line={m.err_line}, expected {line}"


def equivalence(what, source, files):
    """Assembling with includes must equal assembling the flattened source."""
    with_inc = assemble(source, files)
    flat = assemble(flatten(source, files))
    expect_output(flat, flat.output, what + " (flat baseline)")
    assert flat.status == 0, f"{what}: flat baseline failed: {flat.err_msg!r}"
    expect_output(with_inc, flat.output, what)
    return with_inc


def petscii(text):
    return text.replace("\n", "\r").encode("latin1")


def main():
    if not PRG.exists():
        sys.exit("build/modasm.prg not found — run: bash build_modules.sh")

    # 1. Baseline sanity: no includes.
    m = assemble("        *= $C000\nSTART:  LDA #$01\n        STA $D020\n        RTS\n")
    expect_output(m, bytes.fromhex("00c0a9018d20d060"), "baseline")
    print("ok: baseline (no includes)")

    # 2. Single include, labels crossing the file boundary both directions.
    files = {"SUB": petscii("LOOP:   DEX\n        BNE LOOP\n        RTS\n")}
    src = ("        *= $C000\n"
           "        LDX #$05\n"
           "        JSR LOOP\n"          # forward ref into the include
           "        JMP AFTER\n"
           '        .include "SUB"\n'
           "AFTER:  RTS\n")
    m = equivalence("single include", src, files)
    expect_output(m, bytes.fromhex("00c0a2052008c04c0cc0cad0fd6060"), "single include")
    print("ok: single include, cross-file labels")

    # 3. Nested includes; inner .include is the outer file's LAST line
    #    (EOF pop cascade), innermost file has no trailing CR.
    files = {
        "F1": petscii('        LDA #$02\n        .include "F2"'),
        "F2": b"        LDA #$03\r        LDA #$04",   # no trailing CR
    }
    src = ('        *= $C000\n        LDA #$01\n        .include "F1"\n        RTS\n')
    equivalence("nested + EOF cascade + no trailing CR", src, files)
    print("ok: nested includes, EOF cascade, missing trailing CR")

    # 4. Empty include file, and a file that is a single bare CR.
    files = {"MT": b"", "CR": b"\r"}
    src = ('        *= $C000\n        LDA #$01\n        .include "MT"\n'
           '        .include "CR"\n        RTS\n')
    m = assemble(src, files)
    expect_output(m, bytes.fromhex("00c0a90160"), "empty includes")
    print("ok: empty include files")

    # 5. Text after the closing quote is ignored; same file included twice
    #    (LFN must be reusable after close).
    files = {"TW": petscii("        NOP\n")}
    src = ('        *= $C000\n        .include "TW" ; helpers\n'
           '        .include "TW"\n        RTS\n')
    m = assemble(src, files)
    expect_output(m, bytes.fromhex("00c0eaea60"), "double include")
    print("ok: comment after include, same file twice")

    # 6. Deep nesting: 7 levels assemble, 8 levels report INCLUDE TOO DEEP.
    def chain(n):
        fs = {}
        for i in range(1, n):
            fs[f"D{i}"] = petscii(f'        LDA #${i:02X}\n        .include "D{i+1}"\n')
        fs[f"D{n}"] = petscii(f"        LDA #${n:02X}\n")
        return fs
    src = '        *= $C000\n        .include "D1"\n        RTS\n'
    m = equivalence("7-deep nesting", src, chain(7))
    print("ok: 7-deep nesting (maximum)")
    m = Machine(src, chain(8)); m.run(); m.check_clean_finish()
    expect_error(m, "INCLUDE TOO DEEP", "8-deep nesting")
    print("ok: 8-deep nesting rejected")

    # 7. Missing file → I/O ERROR, reported on the .include line.
    m = Machine('        *= $C000\n        NOP\n        .include "NOPE"\n', {})
    m.run(); m.check_clean_finish()
    expect_error(m, "I/O ERROR", "missing file", line=3)
    print("ok: missing include file")

    # 8. Error line numbers are per-file: bad mnemonic on line 2 of the
    #    include reports line 2, not the position in the main source.
    files = {"BAD": petscii("        NOP\n        BOGUS $12\n")}
    m = Machine('        *= $C000\n        NOP\n        NOP\n'
                '        .include "BAD"\n', files)
    m.run(); m.check_clean_finish()
    assert m.status == 1 and m.err_line == 2, (
        f"per-file line numbers: err={m.err_msg!r} line={m.err_line}, expected 2"
    )
    print("ok: per-file error line numbers")

    # 9. After a clean include, a main-file error still reports the
    #    main-file line (counter restored from the frame).
    files = {"OK1": petscii("        NOP\n")}
    m = Machine('        *= $C000\n        .include "OK1"\n        NOP\n'
                "        BOGUS\n", files)
    m.run(); m.check_clean_finish()
    assert m.status == 1 and m.err_line == 4, (
        f"restored line numbers: err={m.err_msg!r} line={m.err_line}, expected 4"
    )
    print("ok: parent line numbers restored after include")

    # 10. Over-long line inside an include → LINE TOO LONG, no hang.
    files = {"LNG": petscii("        NOP\n" + "        LDA #$01" + " " * 100 + "; x\n")}
    m = Machine('        *= $C000\n        .include "LNG"\n', files)
    m.run(); m.check_clean_finish()
    expect_error(m, "LINE TOO LONG", "long line")
    print("ok: over-long include line")

    # 11. .include as the very last line of the main buffer.
    files = {"TAIL": petscii("        LDA #$07\n        RTS\n")}
    src = '        *= $C000\n        .include "TAIL"'   # no trailing newline
    m = assemble(src, files)
    expect_output(m, bytes.fromhex("00c0a90760"), "include on last buffer line")
    print("ok: include on the buffer's last line")

    # 12. A NUL byte inside an included file must not truncate the output.
    files = {"NUL": b"        LDA #$05\r\x00\r        LDA #$06\r"}
    src = ('        *= $C000\n        .include "NUL"\n        RTS\n')
    m = assemble(src, files)
    expect_output(m, bytes.fromhex("00c0a905a90660"), "NUL byte in include")
    print("ok: NUL byte inside include does not truncate")

    # 13. Bigger combined program: data directives + code across 3 files,
    #     verified against the flattened equivalent.
    # NOTE: labels go on their own line — this assembler doesn't support
    # a directive after a label on the same line (see the manual's .text
    # example), which is unrelated to .include.
    files = {
        "DATA": petscii('MSG:\n        .text "HI"\n        .byte $00\n'
                        "TAB:\n        .word MSG,TAB\n"),
        "CODE": petscii("PRINT:  LDA MSG\n        BEQ OUT1\n        JSR $FFD2\n"
                        "OUT1:   RTS\n"),
    }
    src = ('        *= $C000\n        JSR PRINT\n        RTS\n'
           '        .include "DATA"\n        .include "CODE"\n')
    equivalence("mixed directives across files", src, files)
    print("ok: data + code directives across multiple files")

    print("\nall include tests passed")


if __name__ == "__main__":
    main()
