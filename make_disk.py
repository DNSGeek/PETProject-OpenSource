#!/usr/bin/env python3
"""
make_disk.py — Create a PETProject .d64 disk image.

No dependencies beyond the Python standard library.

Usage:
    python3 make_disk.py [--build-dir build] [--name petproject] [--id pp] output.d64

All PRG files found in --build-dir (editor.prg and all mod*.prg files) are
added automatically.  Pass --mega65 to build a MEGA65 image (editor_m65.prg
replaces editor.prg; modules are omitted).
"""

import argparse
import os
import struct

# ── D64 geometry ─────────────────────────────────────────────────────────────

SECTORS_PER_TRACK = (
    [0]  # index 0 unused (tracks are 1-indexed)
    + [21] * 17  # tracks  1-17
    + [19] * 7  # tracks 18-24
    + [18] * 6  # tracks 25-30
    + [17] * 5  # tracks 31-35
)
NUM_TRACKS = 35
DIR_TRACK = 18
BAM_SECTOR = 0
FIRST_DIR_SEC = 1
D64_SIZE = sum(SECTORS_PER_TRACK) * 256  # 174,848 bytes


def track_start(t):
    return sum(SECTORS_PER_TRACK[:t]) * 256


def sec_off(t, s):
    return track_start(t) + s * 256


# ── D64 class ─────────────────────────────────────────────────────────────────


class D64:
    def _init_bam(self):
        bam = bytearray(256)
        bam[0] = DIR_TRACK  # link to first dir sector
        bam[1] = FIRST_DIR_SEC
        bam[2] = 0x41  # DOS version 'A'
        bam[3] = 0x00

        for t in range(1, NUM_TRACKS + 1):
            ns = SECTORS_PER_TRACK[t]
            eoff = 4 + (t - 1) * 4
            if t == DIR_TRACK:
                # Only sectors 0 (BAM) and 1 (first dir sector) are used.
                # Sectors 2-18 are left free so CBM DOS can expand the
                # directory when the initial 8-slot sector fills up.
                # The DOS excludes track 18 from the "BLOCKS FREE" display
                # so these free sectors don't inflate the visible count.
                free_dir = ns - 2  # 17 free (sectors 2-18)
                dir_bits = ((1 << ns) - 1) & ~0x03  # bits 2-18 set, 0-1 clear
                bam[eoff] = free_dir
                bam[eoff + 1] = dir_bits & 0xFF
                bam[eoff + 2] = (dir_bits >> 8) & 0xFF
                bam[eoff + 3] = (dir_bits >> 16) & 0xFF
            else:
                bam[eoff] = ns
                bits = (1 << ns) - 1
                bam[eoff + 1] = bits & 0xFF
                bam[eoff + 2] = (bits >> 8) & 0xFF
                bam[eoff + 3] = (bits >> 16) & 0xFF

        # Disk name — padded with $A0
        nb = self._name.encode("ascii")
        bam[144:160] = nb + bytes([0xA0] * (16 - len(nb)))
        bam[160] = bam[161] = 0xA0
        # Disk ID
        ib = self._id.encode("ascii")
        bam[162:164] = ib + bytes([0xA0] * (2 - len(ib)))
        bam[164] = 0xA0
        bam[165:167] = b"2A"
        bam[167] = bam[168] = 0xA0

        base = sec_off(DIR_TRACK, BAM_SECTOR)
        self._data[base : base + 256] = bam

    # ── directory ───────────────────────────────────────────────────────────

    def _init_dir(self):
        """Initialise first directory sector (track 18 sector 1)."""
        dirsec = bytearray(256)
        dirsec[0] = 0x00  # no next sector (yet; expands automatically)
        dirsec[1] = 0xFF
        base = sec_off(DIR_TRACK, FIRST_DIR_SEC)
        self._data[base : base + 256] = dirsec

    def __init__(self, name="disk", disk_id="pp"):
        self._data = bytearray(D64_SIZE)
        self._name = name[:16].upper()
        self._id = disk_id[:2].upper()
        # Allocation cursor — starts at track 1
        self._alloc_track = 1
        self._alloc_sector = 0

        self._init_bam()
        self._init_dir()

    # ── internal helpers ────────────────────────────────────────────────────

    def _rd(self, t, s, off, n=1):
        base = sec_off(t, s) + off
        return self._data[base : base + n]

    def _wr(self, t, s, off, buf):
        base = sec_off(t, s) + off
        self._data[base : base + len(buf)] = buf

    def _rb(self, t, s, off):
        return self._data[sec_off(t, s) + off]

    def _wb(self, t, s, off, v):
        self._data[sec_off(t, s) + off] = v & 0xFF

    # ── BAM ─────────────────────────────────────────────────────────────────

    def _bam_entry_offset(self, track):
        return sec_off(DIR_TRACK, BAM_SECTOR) + 4 + (track - 1) * 4

    def _bam_alloc(self, track, sector):
        """Mark a sector as allocated in the BAM."""
        eoff = self._bam_entry_offset(track)
        # Decrement free count
        self._data[eoff] -= 1
        # Clear bit
        bits = (
            self._data[eoff + 1]
            | (self._data[eoff + 2] << 8)
            | (self._data[eoff + 3] << 16)
        )
        bits &= ~(1 << sector)
        self._data[eoff + 1] = bits & 0xFF
        self._data[eoff + 2] = (bits >> 8) & 0xFF
        self._data[eoff + 3] = (bits >> 16) & 0xFF

    def _bam_free_count(self, track):
        return self._data[self._bam_entry_offset(track)]

    # ── sector allocation ───────────────────────────────────────────────────

    def _alloc_next(self):
        """Return (track, sector) of next free sector, updating cursor."""
        for _ in range(NUM_TRACKS * 22):
            t = self._alloc_track
            if t > NUM_TRACKS:
                raise RuntimeError("Disk full")
            if t == DIR_TRACK:  # skip directory track for data files
                self._alloc_track += 1
                self._alloc_sector = 0
                continue
            ns = SECTORS_PER_TRACK[t]
            if self._alloc_sector >= ns:
                self._alloc_track += 1
                self._alloc_sector = 0
                continue
            s = self._alloc_sector
            self._alloc_sector += 1
            self._bam_alloc(t, s)
            return t, s
        raise RuntimeError("Disk full")

    def _alloc_dir_sector(self):
        """Allocate a new directory expansion sector from track 18 (sectors 2-18)."""
        ns = SECTORS_PER_TRACK[DIR_TRACK]
        eoff = self._bam_entry_offset(DIR_TRACK)
        bits = (
            self._data[eoff + 1]
            | (self._data[eoff + 2] << 8)
            | (self._data[eoff + 3] << 16)
        )
        for s in range(2, ns):  # 0=BAM, 1=first-dir already used
            if bits & (1 << s):  # bit set = free
                self._data[eoff] -= 1  # decrement free count
                bits &= ~(1 << s)
                self._data[eoff + 1] = bits & 0xFF
                self._data[eoff + 2] = (bits >> 8) & 0xFF
                self._data[eoff + 3] = (bits >> 16) & 0xFF
                # Zero-init the new sector and mark it as the last
                base = sec_off(DIR_TRACK, s)
                self._data[base : base + 256] = bytearray(256)
                self._data[base] = 0x00
                self._data[base + 1] = 0xFF
                return s
        raise RuntimeError("Track 18 full — no room for more directory sectors")

    def _write_dir_entry(self, filename, first_t, first_s, num_blocks, ftype=0x82):
        """Write a directory entry, expanding into a new sector if needed."""
        dt, ds = DIR_TRACK, FIRST_DIR_SEC
        while True:
            base = sec_off(dt, ds)
            next_t = self._data[base]
            next_s = self._data[base + 1]
            # Scan for a free slot in this sector
            for slot in range(8):
                eoff = base + 2 + slot * 32
                if self._data[eoff] == 0:  # file type 0 = scratched/free
                    entry = bytearray(32)
                    entry[0] = ftype
                    entry[1] = first_t
                    entry[2] = first_s
                    nb = filename.upper().encode("ascii")[:16]
                    entry[3 : 3 + len(nb)] = nb
                    for i in range(len(nb), 16):
                        entry[3 + i] = 0xA0
                    struct.pack_into("<H", entry, 28, num_blocks)
                    self._data[eoff : eoff + 32] = entry
                    return
            # Sector is full — expand the directory if this is the last sector
            if next_t == 0:
                new_s = self._alloc_dir_sector()
                self._data[base] = DIR_TRACK  # link to new sector
                self._data[base + 1] = new_s
                dt, ds = DIR_TRACK, new_s
            else:
                dt, ds = next_t, next_s

    # ── public API ──────────────────────────────────────────────────────────

    def add_prg(self, disk_name, file_data):
        """Add a PRG file.  file_data includes the 2-byte load address."""
        if not file_data:
            file_data = bytes(2)

        # Split into 254-byte chunks
        chunks = [file_data[i : i + 254] for i in range(0, len(file_data), 254)]
        if not chunks:
            chunks = [bytes(0)]

        # Allocate sectors
        sectors = [self._alloc_next() for _ in chunks]

        # Write sectors with chaining
        for i, (t, s) in enumerate(sectors):
            sec = bytearray(256)
            chunk = chunks[i]
            if i < len(sectors) - 1:
                nt, ns = sectors[i + 1]
                sec[0], sec[1] = nt, ns
            else:
                sec[0] = 0x00
                sec[1] = len(chunk) + 1  # used bytes in last sector
            sec[2 : 2 + len(chunk)] = chunk
            base = sec_off(t, s)
            self._data[base : base + 256] = sec

        self._write_dir_entry(
            disk_name, sectors[0][0], sectors[0][1], len(sectors), ftype=0x82
        )
        return len(sectors)

    def write(self, path):
        with open(path, "wb") as f:
            f.write(self._data)

    def show_dir(self):
        print(f'\n0 "{self._name:<16s}" {self._id}')
        dt, ds = DIR_TRACK, FIRST_DIR_SEC
        total = 0
        seen = set()
        while True:
            if (dt, ds) in seen:
                break
            seen.add((dt, ds))
            base = sec_off(dt, ds)
            for slot in range(8):
                e = self._data[base + 2 + slot * 32 : base + 2 + (slot + 1) * 32]
                ft = e[0]
                if ft == 0:
                    continue
                name = bytes(b for b in e[3:19] if b != 0xA0).decode(
                    "ascii", errors="?"
                )
                blks = struct.unpack_from("<H", e, 28)[0]
                ts = {0x82: "prg", 0x81: "seq", 0x83: "usr"}.get(ft, "???")
                print(f'  {blks:3d}  "{name}"  {ts}')
                total += blks
            next_t = self._data[base]
            if next_t == 0:
                break
            dt, ds = next_t, self._data[base + 1]
        free = sum(
            self._bam_free_count(t) for t in range(1, NUM_TRACKS + 1) if t != DIR_TRACK
        )
        print(f"{free} blocks free.\n")


# ── entry point ───────────────────────────────────────────────────────────────

# Modules to include: (filename in build dir, disk name used by the editor)
# Disk names must match the PETSCII strings in modules.asm's mod_fname_* tables.
# Modules in disk order.  Disk names must match the PETSCII strings in
# modules.asm's mod_fname_* tables exactly.
MODULES = [
    ("modasm.prg", "MODASM"),
    ("moddet.prg", "MODDET"),
    ("moddis.prg", "MODDIS"),
    ("moddsk.prg", "MODDSK"),
    ("modren.prg", "MODREN"),
    ("modtok.prg", "MODTOK"),
    ("modsfr.prg", "MODSFR"),
    ("modsct.prg", "MODSCT"),
    ("modscr.prg", "MODSCR"),
    ("modscrh.prg", "MODSCRH"),
]


def main():
    ap = argparse.ArgumentParser(
        description="Create PETProject D64 with modules and editor"
    )
    ap.add_argument(
        "--mega65",
        help="Build MEGA65 image (uses editor_m65.prg; omits modules)",
        default=False,
        required=False,
        action="store_true",
    )
    ap.add_argument("output", help="Output .d64 path")
    ap.add_argument(
        "--build-dir",
        default=None,
        help="Build output directory.  When given, editor.prg and "
        "all mod*.prg files are added automatically.",
    )
    ap.add_argument(
        "--name", default="petproject", help="Disk name (default: petproject)"
    )
    ap.add_argument("--id", default="pp", help="Disk ID   (default: pp)")
    args = ap.parse_args()

    disk = D64(name=args.name, disk_id=args.id)

    def add(label, path, diskname):
        if not os.path.exists(path):
            print(f"  {'(skipped)':<10s}           missing: {path}")
            return
        with open(path, "rb") as f:
            data = f.read()
        blks = disk.add_prg(diskname, data)
        print(f"  {diskname:<10s} {blks:3d} blocks  ({len(data):5d} bytes)  ← {label}")

    print("Adding files:")

    # ── Editor first so LOAD"*",8,1 boots straight into the IDE ──────────────
    if args.build_dir:
        editor_prg = "editor_m65.prg" if args.mega65 else "editor.prg"
        add(editor_prg, os.path.join(args.build_dir, "editor.prg"), "PETPROJECT")

    # ── Modules ───────────────────────────────────────────────────────────────
    if args.build_dir and not args.mega65:
        print()
        for fname, diskname in MODULES:
            add(fname, os.path.join(args.build_dir, fname), diskname)

    disk.write(args.output)
    print(f"\nWrote {args.output}")
    disk.show_dir()


if __name__ == "__main__":
    main()
