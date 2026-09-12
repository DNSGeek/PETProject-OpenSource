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
# TARGET selects what to build:
#   all  (default) C64 and C128 sets, one petproject.d64 carrying both — a C64
#                  does LOAD"*",8 and gets the C64 build; a C128 autoboots the
#                  C128 build via the boot sector (boot128.asm).
#   c64            C64 set only, petproject.d64 without the C128 files.
#   c128           C128 set only, build/c128/petproject_c128.d64 (bootable).
# The editor and the modules share zp.inc and layout.inc, so each set is
# assembled with one target selection throughout.
TARGET=${TARGET:-all}
# Extra ca65 flags on top of what a target implies. Exported as-is so that
# build_modules.sh adds the target define itself, exactly once.
CA65FLAGS=${CA65FLAGS:-}
export CA65FLAGS

# ── Paths ─────────────────────────────────────────────────────────────────────
SRC="$(cd "$(dirname "$0")" && pwd)" # directory containing this script
BUILD64="${SRC}/build"
BUILD128="${SRC}/build/c128"

case "${TARGET}" in
  all | c64 | c128) ;;
  *)
    echo "Unknown TARGET '${TARGET}' (expected all, c64 or c128)" >&2
    exit 1
    ;;
esac

# ── Build one target: editor + modules (+ boot sector for the C128) ──────────
build_target() {
  local target=$1 build cfg asflags
  case "${target}" in
    c64)
      build="${BUILD64}"
      cfg="${SRC}/petproject.cfg"
      asflags="${CA65FLAGS}"
      ;;
    c128)
      build="${BUILD128}"
      cfg="${SRC}/petproject_c128.cfg"
      asflags="-D TARGET_C128 ${CA65FLAGS}"
      ;;
  esac
  mkdir -p "${build}"
  rm -f "${build}"/*.o "${build}"/*.prg "${build}"/*.bin "${build}"/*.dbg "${build}"/*.map "${build}"/*.d64

  echo "Building editor (${target})..."
  # shellcheck disable=SC2086  # asflags is intentionally word-split
  ${CA65} ${asflags} -v -t c64 \
    -o "${build}/editor.o" \
    -g "${SRC}/editor.asm" || exit 1

  ${LD65} -v -C "${cfg}" \
    -o "${build}/editor.prg" \
    --mapfile "${build}/editor.map" \
    --dbgfile "${build}/editor.dbg" \
    "${build}/editor.o" || exit 1

  echo "✓ ${build}/editor.prg"

  TARGET="${target}" bash "${SRC}/build_modules.sh" || exit 1

  if [[ "${target}" == c128 ]]; then
    echo "Building C128 boot sector..."
    # shellcheck disable=SC2086
    ${CA65} ${asflags} -t none -o "${build}/boot128.o" "${SRC}/boot128.asm" || exit 1
    ${LD65} -C "${SRC}/boot128.cfg" -o "${build}/boot128.bin" "${build}/boot128.o" || exit 1
    echo "✓ ${build}/boot128.bin"
  fi
  rm -f "${build}"/*.o
}

# ── Clean, build, package ────────────────────────────────────────────────────
if [[ "${TARGET}" != c128 ]]; then
  rm -f "${SRC}/petproject.d64" "${SRC}"/*.vsf "${SRC}"/*.reu
fi

case "${TARGET}" in
  all)
    build_target c64
    build_target c128
    python3 "${SRC}/make_disk.py" \
      --build-dir "${BUILD64}" \
      --c128-build-dir "${BUILD128}" \
      --boot-sector "${BUILD128}/boot128.bin" \
      --name petproject \
      --id pp \
      "${SRC}/petproject.d64" || exit 1
    echo ""
    echo "Build complete: ${SRC}/petproject.d64 (C64 + C128, C128-bootable)"
    ;;
  c64)
    build_target c64
    python3 "${SRC}/make_disk.py" \
      --build-dir "${BUILD64}" \
      --name petproject \
      --id pp \
      "${SRC}/petproject.d64" || exit 1
    echo ""
    echo "Build complete: ${SRC}/petproject.d64 (C64 only)"
    ;;
  c128)
    build_target c128
    python3 "${SRC}/make_disk.py" \
      --c128-build-dir "${BUILD128}" \
      --boot-sector "${BUILD128}/boot128.bin" \
      --name petproject \
      --id pp \
      "${BUILD128}/petproject_c128.d64" || exit 1
    echo ""
    echo "Build complete: ${BUILD128}/petproject_c128.d64 (C128 only, bootable)"
    ;;
esac

# ── Optional: launch in VICE ──────────────────────────────────────────────────
# Set X64SC to your x64sc binary to auto-launch after building, e.g.:
#   X64SC=/opt/homebrew/bin/x64sc bash make_petproject.sh
# (Runs only when X64SC is set, so the build works on machines without VICE.)
if [[ -n "${X64SC:-}" ]]; then
  "${X64SC}" -basicload -autostart "${SRC}/petproject.d64"
fi
