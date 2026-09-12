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
# TARGET selects the memory map for BOTH the editor and the modules (they
# share zp.inc and layout.inc, so they must agree): c64 (default) or c128.
#   TARGET=c128 bash make_petproject.sh
# builds into build/c128 with petproject_c128.cfg and the *_c128.cfg module
# configs, and writes build/c128/petproject_c128.d64 (a plain disk: no
# C128 boot sector yet — see docs/c128-port-notes.md, Phase 3).
TARGET=${TARGET:-c64}
# Extra ca65 flags on top of what TARGET implies. Exported as-is so that
# build_modules.sh adds the target define itself, exactly once.
CA65FLAGS=${CA65FLAGS:-}
export TARGET CA65FLAGS

# ── Paths ─────────────────────────────────────────────────────────────────────
SRC="$(cd "$(dirname "$0")" && pwd)" # directory containing this script
case "${TARGET}" in
  c64)
    BUILD="${SRC}/build"
    EDITOR_CFG="${SRC}/petproject.cfg"
    EDITOR_ASFLAGS="${CA65FLAGS}"
    ;;
  c128)
    BUILD="${SRC}/build/c128"
    EDITOR_CFG="${SRC}/petproject_c128.cfg"
    EDITOR_ASFLAGS="-D TARGET_C128 ${CA65FLAGS}"
    ;;
  *)
    echo "Unknown TARGET '${TARGET}' (expected c64 or c128)" >&2
    exit 1
    ;;
esac

mkdir -p "${BUILD}"

# ── Clean previous build artifacts ───────────────────────────────────────────
if [[ "${TARGET}" == c64 ]]; then
  rm -f "${SRC}/petproject.d64" "${SRC}"/*.vsf "${SRC}"/*.reu
fi
rm -f "${BUILD}"/*.o "${BUILD}"/*.prg "${BUILD}"/*.dbg "${BUILD}"/*.map

# ── Build editor ──────────────────────────────────────────────────────────────
echo "Building editor..."
# shellcheck disable=SC2086  # EDITOR_ASFLAGS is intentionally word-split
${CA65} ${EDITOR_ASFLAGS} -v -t c64 \
  -o "${BUILD}/editor.o" \
  -g "${SRC}/editor.asm" || exit 1

${LD65} -v -C "${EDITOR_CFG}" \
  -o "${BUILD}/editor.prg" \
  --mapfile "${BUILD}/editor.map" \
  --dbgfile "${BUILD}/editor.dbg" \
  "${BUILD}/editor.o" || exit 1

echo "✓ ${BUILD}/editor.prg"

# ── Build modules ─────────────────────────────────────────────────────────────
bash "${SRC}/build_modules.sh" || exit 1

# ── Create disk image ─────────────────────────────────────────────────────────
if [[ "${TARGET}" != c64 ]]; then
  # Plain disk, no C128 boot sector yet: LOAD"PETPROJECT",8 then RUN from
  # BASIC 7.0 (or let VICE autostart it). See docs/c128-port-notes.md, Phase 3.
  python3 "${SRC}/make_disk.py" \
    --build-dir "${BUILD}" \
    --name petproject \
    --id pp \
    "${BUILD}/petproject_${TARGET}.d64" || exit 1
  rm -f "${BUILD}"/*.o
  echo ""
  echo "Build complete (${TARGET}): ${BUILD}/petproject_${TARGET}.d64"
  exit 0
fi
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
