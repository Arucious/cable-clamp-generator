import os, stat, tempfile
from pathlib import Path
import pytest
from conftest import render_scad, measure_stl

# The openGrid snap geometry (BOSL2 tag_diff nubs) produces T-junction edges when
# exported by the Manifold backend, which trimesh flags as non-watertight.
# CGAL performs full Nef-polyhedron Boolean evaluation that eliminates them.
# Use a thin wrapper so render_scad picks up CGAL for all tests in this module.
@pytest.fixture(autouse=True, scope="module")
def _cgal_backend(tmp_path_factory):
    wrapper = tmp_path_factory.mktemp("wrap") / "openscad_cgal"
    wrapper.write_text(
        "#!/bin/sh\n"
        'exec /Applications/OpenSCAD-2026.01.14.app/Contents/MacOS/OpenSCAD'
        ' --backend CGAL "$@"\n'
    )
    wrapper.chmod(wrapper.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    old = os.environ.get("OPENSCAD_BIN")
    os.environ["OPENSCAD_BIN"] = str(wrapper)
    yield
    if old is None:
        os.environ.pop("OPENSCAD_BIN", None)
    else:
        os.environ["OPENSCAD_BIN"] = old


LIB = '''
use <clamp.scad>
include <BOSL2/std.scad>
'''

def test_clamp_body_is_one_watertight_solid(tmp_path):
    src = LIB + ('clamp_body(mount_system="openGrid snap", board_type="Lite", '
                 'bore=10, preset="openGrid standard", socket_height=14, clearance=0.4);')
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["watertight"] is True
    assert m["bounds"][0][2] <= -3.5    # down through the lite snap (~ -4)
    assert m["bounds"][1][2] >= 13.5    # up through the socket top (~14)

def test_clamp_body_cable_channel_open_along_y(tmp_path):
    src = LIB + ('union(){ clamp_body(mount_system="openGrid snap", board_type="Lite", '
                 'bore=10, preset="openGrid standard", socket_height=14, clearance=0.4); '
                 'translate([0,0,5]) cube([6,60,6],center=true); }')
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["bbox"][1] >= 55   # probe rod protrudes front+back -> channel open

def test_ring_nut_watertight(tmp_path):
    src = LIB + 'ring_nut(bore=10, preset="openGrid standard", height=8, clearance=0.4, grip="Flats");'
    m = measure_stl(render_scad(src, {}, tmp_path))
    assert m["watertight"] is True
