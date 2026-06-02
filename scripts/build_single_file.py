#!/usr/bin/env python3
"""Flatten the multi-file generator into ONE self-contained .scad for MakerWorld.

MakerWorld's Parametric Model Maker does NOT accept dependency .scad uploads — only a single
.scad that uses pre-installed libraries (BOSL2). This concatenates our files, strips all LOCAL
use/include lines (their content is inlined), and keeps only `include <BOSL2/...>`.

OpenSCAD evaluates top-level variable assignments in textual order, and a function called by an
early top-level var cannot see a global defined later. So we emit, in order:
  1. BOSL2 includes + $fa/$fs
  2. the customizer parameters (literals only — MakerWorld reads these at the top for its UI)
  3. ALL definitions (our functions/modules + the inlined libraries)
  4. the derived `_` vars + asserts + the part-switch geometry  (the main file's `[Hidden]` section)

Output: dist/cable_clamp_generator_single.scad  (upload THIS to MakerWorld).
"""
import re, pathlib

REPO = pathlib.Path(__file__).resolve().parent.parent
CC = REPO / "cable_clamp"

MAIN = "cable_clamp_generator.scad"
LIBS = ["params.scad", "thread.scad", "mount.scad", "clamp.scad",
        "opengrid_base.scad", "opengrid_threads_lib.scad", "opengrid_snap_lib.scad",
        "openconnect_lib.scad", "multiconnectSlotDesign.scad"]

LOCAL_INC = re.compile(r'^\s*(use|include)\s*<(?!BOSL2/)[^>]+>\s*;?\s*(//.*)?$')   # drop (inlined)
BOSL_INC  = re.compile(r'^\s*include\s*<(BOSL2/[^>]+)>')
seen_bosl = set()

def clean(name, lines, drop_og_snap=False):
    out = []
    for line in lines:
        if LOCAL_INC.match(line):
            continue
        m = BOSL_INC.match(line)
        if m:
            if m.group(1) in seen_bosl:
                continue
            seen_bosl.add(m.group(1))
        if drop_og_snap and re.match(r'^\s*OG_SNAP_WIDTH\s*=', line):
            continue   # defined in params.scad; avoid a duplicate-assignment warning
        out.append(line)
    return out

# --- split the main file at the `[Hidden]` marker: params (top) vs derived+geometry (bottom) ---
main_lines = (CC / MAIN).read_text().splitlines()
split = next(i for i, l in enumerate(main_lines) if "[Hidden]" in l)
main_head = clean(MAIN, main_lines[:split])     # includes, $fa/$fs, customizer params
main_tail = clean(MAIN, main_lines[split:])     # derived vars, asserts, _body/_nut, geometry

parts = ["// AUTO-GENERATED single-file build (scripts/build_single_file.py).",
         "// Upload THIS file to MakerWorld's Parametric Model Maker. BOSL2 is provided by the",
         "// platform; everything else is inlined below. Edit sources in cable_clamp/ and re-run.",
         "\n// ===================== customizer parameters (main) ====================="]
parts += main_head
for name in LIBS:
    parts.append(f"\n// ===================== {name} =====================")
    parts += clean(name, (CC / name).read_text().splitlines(), drop_og_snap=(name != "params.scad"))
parts.append("\n// ===================== derived values + geometry (main) =====================")
parts += main_tail

# Committed at the repo root as the ready-to-upload MakerWorld file (regenerate by re-running this).
dest = REPO / "cable_clamp_generator_single.scad"
dest.write_text("\n".join(parts) + "\n")
print("wrote", dest, "\nBOSL2 includes:", sorted(seen_bosl))
