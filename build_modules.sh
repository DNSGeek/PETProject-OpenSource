#!/bin/bash
# build_modules.sh — Build all PETProject loadable modules.
#
# Run from the PETProject source directory.
# Requires ca65 and ld65 in PATH, or override via CA65/LD65 environment
# variables (e.g. CA65=/opt/homebrew/bin/ca65 bash build_modules.sh).

CA65=${CA65:-ca65}
LD65=${LD65:-ld65}
# TARGET selects the memory map: c64 (default) or c128. For c128 the modules
# are assembled with -D TARGET_C128 (zp_c128.inc + layout.inc), linked with
# the *_c128.cfg configs where one exists, written to build/c128, and the
# script runner (modscr, modscrh) is skipped — it is not part of the C128
# port. Must match the target the editor is built with; make_petproject.sh
# exports it.
TARGET=${TARGET:-c64}
# Extra ca65 flags on top of what TARGET implies.
CA65FLAGS=${CA65FLAGS:-}
case "${TARGET}" in
  c64) BUILD=build ;;
  c128)
    BUILD=build/c128
    CA65FLAGS="-D TARGET_C128 ${CA65FLAGS}"
    ;;
  *)
    echo "Unknown TARGET '${TARGET}' (expected c64 or c128)" >&2
    exit 1
    ;;
esac

mkdir -p "${BUILD}"

build_module() {
  local name=${1}
  local cfg
  echo "Building ${name}..."
  # Per-module config wins over the shared one; a _${TARGET} variant wins
  # over the plain file (the $A000 modules share theirs across targets).
  if [[ "${TARGET}" != c64 && -f "${name}_${TARGET}.cfg" ]]; then
    cfg="${name}_${TARGET}.cfg"
  elif [[ -f "${name}.cfg" ]]; then
    cfg="${name}.cfg"
  elif [[ "${TARGET}" != c64 && -f "module_${TARGET}.cfg" ]]; then
    cfg="module_${TARGET}.cfg"
  else
    cfg=module.cfg
  fi
  echo "  Using: ${cfg}"
  # shellcheck disable=SC2086  # CA65FLAGS is intentionally word-split
  if ! ${CA65} ${CA65FLAGS} -t none -g -o "${BUILD}/${name}.o" "${name}.asm"; then
    echo "✗ Assembly failed: ${name}"
    return 1
  fi
  if ! ${LD65} -C "${cfg}" -o "${BUILD}/${name}.prg" \
    --mapfile "${BUILD}/${name}.map" \
    --dbgfile "${BUILD}/${name}.dbg" \
    "${BUILD}/${name}.o"; then
    echo "✗ Link failed: ${name}"
    return 1
  fi
  local bytes
  bytes=$(wc -c <"${BUILD}/${name}.prg")
  echo "✓ ${BUILD}/${name}.prg  ${bytes} bytes"
}

build_module moddet || exit 1
build_module modtok || exit 1
build_module modasm || exit 1
build_module moddsk || exit 1
build_module moddis || exit 1
build_module modren || exit 1
build_module modsfr || exit 1
build_module modsct || exit 1
if [[ "${TARGET}" == c64 ]]; then
  build_module modscr || exit 1
  build_module modscrh || exit 1
else
  echo "Skipping modscr/modscrh: the script runner is not part of the ${TARGET} port."
fi
rm -f "${BUILD}"/*.o
