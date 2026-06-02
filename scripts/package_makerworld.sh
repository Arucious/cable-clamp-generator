#!/usr/bin/env bash
# Assemble the exact fileset to upload to MakerWorld's Parametric Model Maker.
# BOSL2 is intentionally EXCLUDED — MakerWorld provides it.
set -euo pipefail
cd "$(dirname "$0")/.."
out="dist/makerworld"
rm -rf "$out" && mkdir -p "$out"
cp cable_clamp/cable_clamp_generator.scad \
   cable_clamp/params.scad cable_clamp/thread.scad cable_clamp/mount.scad cable_clamp/clamp.scad \
   cable_clamp/opengrid_base.scad cable_clamp/opengrid_threads_lib.scad \
   cable_clamp/opengrid_snap_lib.scad cable_clamp/openconnect_lib.scad \
   cable_clamp/multiconnectSlotDesign.scad \
   "$out/"
echo "Upload these (main file = cable_clamp_generator.scad):"; ls -1 "$out"
