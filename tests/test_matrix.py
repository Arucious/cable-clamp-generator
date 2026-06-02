import pytest
from conftest import render_file, measure_stl

GEN = "cable_clamp/cable_clamp_generator.scad"

MOUNTS = [
    {"Mount_System": "openGrid snap", "Board_Type": "Lite"},
    {"Mount_System": "openGrid snap", "Board_Type": "Full"},
    {"Mount_System": "openConnect"},
    {"Mount_System": "Multiboard", "MB_Slots": 1},
]
BORES = [5, 16]
PARTS = ["Body", "Ring Nut"]

@pytest.mark.parametrize("mount,bore,part",
    [(m, b, p) for m in MOUNTS for b in BORES for p in PARTS])
def test_matrix_renders_watertight(mount, bore, part, tmp_path):
    params = {**mount, "Cable_Bore_Diameter": bore, "Part": part}
    m = measure_stl(render_file(GEN, params, tmp_path, backend="CGAL"))
    assert m["watertight"] is True, f"non-manifold for {params}"
