from conftest import render_file, measure_stl

GEN = "cable_clamp/cable_clamp_generator.scad"

def test_generator_body_default(tmp_path):
    m = measure_stl(render_file(GEN, {"Part": "Body"}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True

def test_generator_ring_nut(tmp_path):
    m = measure_stl(render_file(GEN, {"Part": "Ring Nut"}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True

def test_generator_clamps_oversize_bore_without_error(tmp_path):
    # bore beyond the openGrid cell ceiling must be clamped, not error out. Warnings OFF so we
    # measure the pure clamped geometry. The clamp accounts for the base flare too (part_od), so
    # nothing exceeds the snap envelope (~25.59 mm). Tight tolerance catches a flare overhang.
    m = measure_stl(render_file(GEN, {"Part": "Body", "Cable_Bore_Diameter": 40,
                                      "Preview_Warnings": False}, tmp_path))
    assert m["bbox"][0] <= 25.59 + 0.15, "clamped part (incl. base flare) overhangs the cell"
    assert m["bbox"][1] <= 25.59 + 0.15

def test_generator_shows_warning_label_when_clamped(tmp_path):
    # With warnings on (default), an over-size bore floats a wide red text label above the part,
    # so a MakerWorld user sees it. Its width far exceeds the ~25.6 mm clamp envelope.
    clamped = measure_stl(render_file(GEN, {"Part": "Body", "Cable_Bore_Diameter": 40}, tmp_path))
    assert clamped["bbox"][0] > 35, "expected a visible warning label wider than the part"
    # in range -> no label, normal envelope
    ok = measure_stl(render_file(GEN, {"Part": "Body", "Cable_Bore_Diameter": 10}, tmp_path))
    assert ok["bbox"][0] <= 25.59 + 0.5

def test_generator_multiboard_allows_larger_bore(tmp_path):
    m = measure_stl(render_file(GEN, {"Part": "Body", "Mount_System": "Multiboard",
                                      "MB_Slots": 2, "Cable_Bore_Diameter": 22}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True
