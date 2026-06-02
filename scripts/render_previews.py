#!/usr/bin/env python3
"""Render preview PNGs for the README/deliverables across the mount matrix."""
import os, subprocess
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
GEN  = REPO / "cable_clamp/cable_clamp_generator.scad"
OUT  = REPO / "cable_clamp/previews"; OUT.mkdir(exist_ok=True)
BIN    = os.environ.get("OPENSCAD_BIN", "/Applications/OpenSCAD-2026.01.14.app/Contents/MacOS/OpenSCAD")
LIBDIR = os.environ.get("OPENSCAD_LIBDIR", str(Path.home()/"Documents/OpenSCAD/libraries"))
ENV = {**os.environ, "OPENSCADPATH": LIBDIR}  # GEN rendered in place, its own includes resolve

CONFIGS = [
    ("opengrid_lite_b8",  {"Mount_System":"openGrid snap","Board_Type":"Lite","Cable_Bore_Diameter":8,"Part":"Both (preview)"}),
    ("opengrid_full_b14", {"Mount_System":"openGrid snap","Board_Type":"Full","Cable_Bore_Diameter":14,"Part":"Both (preview)"}),
    ("openconnect_b10",   {"Mount_System":"openConnect","Cable_Bore_Diameter":10,"Part":"Both (preview)"}),
    ("multiboard_b16",    {"Mount_System":"Multiboard","MB_Slots":1,"Cable_Bore_Diameter":16,"Part":"Both (preview)"}),
]
def fmt(v): return ("true" if v else "false") if isinstance(v,bool) else (f'"{v}"' if isinstance(v,str) else str(v))
for name, params in CONFIGS:
    cmd = [BIN, "-o", str(OUT/f"{name}.png"), "--imgsize=900,700", "--viewall", "--autocenter"]
    for k,v in params.items(): cmd += ["-D", f"{k}={fmt(v)}"]
    cmd += [str(GEN)]
    print("render", name); subprocess.run(cmd, check=True, env=ENV)
print("done ->", OUT)
