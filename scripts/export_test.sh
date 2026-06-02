#!/usr/bin/env bash
# Export a ready-to-print TEST clamp with sensible defaults:
#   openGrid snap, Lite board (4mm), 10mm cable bore, openGrid-standard thread, Flats grip.
# Produces separate 3MF files for the Body and the Ring Nut (print both).
set -euo pipefail
cd "$(dirname "$0")/.."
OSB="${OPENSCAD_BIN:-/Applications/OpenSCAD-2026.01.14.app/Contents/MacOS/OpenSCAD}"
LIB="${OPENSCAD_LIBDIR:-$HOME/Documents/OpenSCAD/libraries}"
GEN="cable_clamp/cable_clamp_generator.scad"
out="build/test_print"; rm -rf "$out"; mkdir -p "$out"

# Body + knurled Ring Nut (one openGrid Lite cell, 10mm bore). STL = pure geometry, no embedded
# slicer/material settings (so you can pick any filament). Manifold backend = MakerWorld parity.
OPENSCADPATH="$LIB" "$OSB" --export-format binstl -o "$out/cable_clamp_body.stl"     -D 'Part="Body"'                          "$GEN"
OPENSCADPATH="$LIB" "$OSB" --export-format binstl -o "$out/cable_clamp_ring_nut.stl" -D 'Part="Ring Nut"' -D 'Nut_Grip="Knurl"' "$GEN"

echo "Test-print files (openGrid snap / Lite / 10mm bore) -> $out"
ls -1 "$out"
