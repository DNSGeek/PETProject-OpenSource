#!/bin/bash
# build_modules.sh — Build all PETProject loadable modules.
#
# Run from the PETProject source directory.
# Requires ca65 and ld65 in PATH, or override via CA65/LD65 environment
# variables (e.g. CA65=/opt/homebrew/bin/ca65 bash build_modules.sh).

CA65=${CA65:-ca65}
LD65=${LD65:-ld65}
BUILD=build

mkdir -p "${BUILD}"

build_module() {
  local name=${1}
  local cfg
  echo "Building ${name}..."
  if [[ -f "${name}.cfg" ]]; then
    cfg="${name}.cfg"
    echo "  Using: ${cfg}"
  else
    cfg=module.cfg
  fi
  if ! ${CA65} -t none -o "${BUILD}/${name}.o" "${name}.asm"; then
    echo "✗ Assembly failed: ${name}"
    return 1
  fi
  if ! ${LD65} -C "${cfg}" -o "${BUILD}/${name}.prg" "${BUILD}/${name}.o"; then
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
build_module modscr || exit 1
build_module modscrh || exit 1
