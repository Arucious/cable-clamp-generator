from conftest import render_scad, measure_stl

LIB = '''
use <params.scad>
use <thread.scad>
include <BOSL2/std.scad>
'''

def test_socket_outer_diameter_scales_with_bore(tmp_path):
    src = LIB + 'threaded_socket(bore=10, preset="openGrid standard", height=12, clearance=0.4);'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert 13.0 <= m["bbox"][0] <= 24.8     # OD > bore and within the cell
    assert m["bbox"][2] == 12.0             # height honored

def test_socket_watertight(tmp_path):
    src = LIB + 'threaded_socket(bore=10, preset="openGrid standard", height=12, clearance=0.4);'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["watertight"] is True

def test_nut_plug_height_and_watertight(tmp_path):
    src = LIB + 'nut_plug(bore=10, preset="openGrid standard", height=8, clearance=0.4, grip="Flats");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["bbox"][2] >= 8.0
    assert m["watertight"] is True
