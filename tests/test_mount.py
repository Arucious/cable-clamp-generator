from conftest import render_scad, measure_stl

LIB = '''
use <mount.scad>
include <BOSL2/std.scad>
'''

def test_opengrid_snap_footprint_and_thickness_lite(tmp_path):
    src = LIB + 'mount(mount_system="openGrid snap", board_type="Lite", snap_shape="Symmetric");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert 24.8 <= m["bbox"][0] <= 28.0 and 24.8 <= m["bbox"][1] <= 28.0  # snap width + retention nubs, fits the 28mm cell
    assert abs(m["bbox"][2] - 4.0) < 0.2

def test_opengrid_snap_thickness_full(tmp_path):
    src = LIB + 'mount(mount_system="openGrid snap", board_type="Full", snap_shape="Symmetric");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert abs(m["bbox"][2] - 6.8) < 0.2

def test_mount_attachment_is_below_z0(tmp_path):
    src = LIB + 'mount(mount_system="openGrid snap", board_type="Lite", snap_shape="Symmetric");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["bounds"][1][2] <= 0.05   # mating face at z=0 (max z ~ 0)

def test_openconnect_mount_within_cell_and_below_z0(tmp_path):
    src = LIB + 'mount(mount_system="openConnect", oc_slots=1, oc_slide="Up", oc_lock=true);'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["bbox"][0] <= 24.8 + 0.2 and m["bbox"][1] <= 24.8 + 0.2   # fits a cell
    assert m["bounds"][1][2] <= 0.05                                    # mating face at z=0
    assert m["watertight"] is True
    # the openConnect slot must actually be carved (a real receiver, not a solid plate):
    solid = m["bbox"][0] * m["bbox"][1] * m["bbox"][2]
    assert m["volume"] < 0.97 * solid, "no slot cavity present — receiver not carved"

def test_multiboard_plate_width_one_slot(tmp_path):
    src = LIB + 'mount(mount_system="Multiboard", mb_slots=1, mb_dimples=true, mb_onramp=true);'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert abs(m["bbox"][0] - 25.0) < 1.0
    assert m["bounds"][1][2] <= 0.05            # mating face at z=0
    assert m["watertight"] is True
    solid = m["bbox"][0]*m["bbox"][1]*m["bbox"][2]
    assert m["volume"] < 0.97 * solid           # slots genuinely carved

def test_multiboard_plate_width_two_slots(tmp_path):
    src = LIB + 'mount(mount_system="Multiboard", mb_slots=2);'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert abs(m["bbox"][0] - 50.0) < 1.5

def test_multiboard_no_dimples_still_watertight(tmp_path):
    src = LIB + 'mount(mount_system="Multiboard", mb_slots=1, mb_dimples=false);'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["watertight"] is True              # proves the parameter path works
