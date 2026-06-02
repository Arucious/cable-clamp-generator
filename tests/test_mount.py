from conftest import render_scad, measure_stl

LIB = '''
use <mount.scad>
include <BOSL2/std.scad>
'''

def test_opengrid_snap_footprint_and_thickness_lite(tmp_path):
    src = LIB + 'mount(mount_system="openGrid snap", board_type="Lite", snap_shape="Symmetric");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert abs(m["bbox"][0] - 24.8) < 0.2 and abs(m["bbox"][1] - 24.8) < 0.2
    assert abs(m["bbox"][2] - 4.0) < 0.2

def test_opengrid_snap_thickness_full(tmp_path):
    src = LIB + 'mount(mount_system="openGrid snap", board_type="Full", snap_shape="Symmetric");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert abs(m["bbox"][2] - 6.8) < 0.2

def test_mount_attachment_is_below_z0(tmp_path):
    src = LIB + 'mount(mount_system="openGrid snap", board_type="Lite", snap_shape="Symmetric");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["bounds"][1][2] <= 0.05   # mating face at z=0 (max z ~ 0)
