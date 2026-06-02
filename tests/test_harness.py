from conftest import render_scad, measure_stl

def test_harness_renders_and_measures(tmp_path):
    scad = 'cube([10, 20, 30], center=true);'
    stl = render_scad(scad, params={}, tmp_path=tmp_path)
    m = measure_stl(stl)
    assert m["bbox"] == (10.0, 20.0, 30.0)
    assert m["watertight"] is True
