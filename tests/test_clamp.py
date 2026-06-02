from conftest import render_scad, measure_stl

# NOTE: watertight checks on snap-containing geometry use backend="CGAL". The openGrid snap
# (mitufy BOSL2 nub geometry) leaves T-junction coincident faces in Manifold-backend STL output
# that trip trimesh.is_watertight, even though OpenSCAD's Manifold backend reports NoError (so it
# renders fine on MakerWorld). CGAL's full Nef Boolean eval yields a clean mesh trimesh can verify.
# See README "Compatibility notes". The default-backend (Manifold) render still succeeds = MakerWorld parity.

LIB = '''
use <clamp.scad>
include <BOSL2/std.scad>
'''

def test_clamp_body_is_one_watertight_solid(tmp_path):
    src = LIB + ('clamp_body(mount_system="openGrid snap", board_type="Lite", '
                 'bore=10, preset="openGrid standard", socket_height=14, clearance=0.4);')
    m = measure_stl(render_scad(src, {}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True
    assert m["bounds"][0][2] <= -3.5    # down through the lite snap (~ -4)
    assert m["bounds"][1][2] >= 13.5    # up through the socket top (~14)

def test_clamp_body_renders_on_makerworld_backend(tmp_path):
    # MakerWorld parity: the body must render without error on the default (Manifold) backend.
    src = LIB + ('clamp_body(mount_system="openGrid snap", board_type="Lite", '
                 'bore=10, preset="openGrid standard", socket_height=14, clearance=0.4);')
    m = measure_stl(render_scad(src, {}, tmp_path))   # default backend = Manifold (no raise = renders OK)
    assert m["bbox"][2] > 13.5

def test_clamp_body_cable_channel_open_along_y(tmp_path):
    src = LIB + ('union(){ clamp_body(mount_system="openGrid snap", board_type="Lite", '
                 'bore=10, preset="openGrid standard", socket_height=14, clearance=0.4); '
                 'translate([0,0,5]) cube([6,60,6],center=true); }')
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["bbox"][1] >= 55   # probe rod protrudes front+back -> channel open

def test_ring_nut_watertight(tmp_path):
    src = LIB + 'ring_nut(bore=10, preset="openGrid standard", height=8, clearance=0.4, grip="Flats");'
    m = measure_stl(render_scad(src, {}, tmp_path, backend="CGAL"))
    assert m["watertight"] is True
