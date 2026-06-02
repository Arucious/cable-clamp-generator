from conftest import render_file, measure_stl

GEN = "cable_clamp/cable_clamp_generator.scad"

def test_generator_body_default(tmp_path):
    m = measure_stl(render_file(GEN, {"Part": "Body"}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True

def test_generator_ring_nut(tmp_path):
    m = measure_stl(render_file(GEN, {"Part": "Ring Nut"}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True

def test_generator_clamps_oversize_bore_without_error(tmp_path):
    # bore beyond the openGrid cell ceiling must be clamped, not error out.
    # The openGrid snap nubs extend the outer envelope to ~25.59 mm regardless of bore.
    # Threshold is 26.1 (25.59 + 0.5) — well below what unclamped bore=40 would produce (~47 mm).
    m = measure_stl(render_file(GEN, {"Part": "Body", "Cable_Bore_Diameter": 40}, tmp_path))
    assert m["bbox"][0] <= 25.59 + 0.5

def test_generator_multiboard_allows_larger_bore(tmp_path):
    m = measure_stl(render_file(GEN, {"Part": "Body", "Mount_System": "Multiboard",
                                      "MB_Slots": 2, "Cable_Bore_Diameter": 22}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True
