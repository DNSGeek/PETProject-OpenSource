#!/bin/bash
# make_petproject.sh — Full build script for PETProject.
#
# Builds the editor PRG, all modules, and the .d64 disk image.
# Run from the PETProject source directory.
#
# Requirements: ca65 and ld65 must be in PATH (or set CA65/LD65 below).
# Tested with cc65 v2.19+.
#
# To launch in VICE after building, uncomment the x64sc line at the bottom
# and adjust the path to your x64sc binary.

set -euo pipefail

# ── Toolchain (override with environment variables if needed) ─────────────────
CA65=${CA65:-ca65}
LD65=${LD65:-ld65}

# ── Paths ─────────────────────────────────────────────────────────────────────
SRC="$(cd "$(dirname "$0")" && pwd)" # directory containing this script
BUILD="${SRC}/build"

mkdir -p "${BUILD}"

# ── Clean previous build artifacts ───────────────────────────────────────────
rm -f "${SRC}/petproject.d64" "${SRC}"/*.vsf "${SRC}"/*.reu
rm -f "${BUILD}"/*.o "${BUILD}"/*.prg "${BUILD}"/*.dbg "${BUILD}"/*.map

# ── Build editor ──────────────────────────────────────────────────────────────
echo "Building editor..."
${CA65} -v -t c64 \
  -o "${BUILD}/editor.o" \
  -g "${SRC}/editor.asm" || exit 1

${LD65} -v -C "${SRC}/petproject.cfg" \
  -o "${BUILD}/editor.prg" \
  --mapfile "${BUILD}/editor.map" \
  --dbgfile "${BUILD}/editor.dbg" \
  "${BUILD}/editor.o" || exit 1

echo "✓ ${BUILD}/editor.prg"

# ── Build modules ─────────────────────────────────────────────────────────────
bash "${SRC}/build_modules.sh" || exit 1

# ── Create disk image ─────────────────────────────────────────────────────────
python3 "${SRC}/make_disk.py" \
  --build-dir "${BUILD}" \
  --name petproject \
  --id pp \
  "${SRC}/petproject.d64" || exit 1

rm -f "${BUILD}"/*.o
echo ""
echo "Build complete: ${SRC}/petproject.d64"

# ── Optional: launch in VICE ──────────────────────────────────────────────────
# Set X64SC to your x64sc binary to auto-launch after building, e.g.:
#   X64SC=/opt/homebrew/bin/x64sc bash make_petproject.sh
# (Runs only when X64SC is set, so the build works on machines without VICE.)
if [[ -n "${X64SC:-}" ]]; then
  "${X64SC}" -basicload -autostart "${SRC}/petproject.d64"
fi
