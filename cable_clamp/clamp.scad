use <mount.scad>
use <thread.scad>
use <params.scad>
include <BOSL2/std.scad>

module clamp_body(mount_system, board_type="Lite", snap_shape="Symmetric",
                  oc_slots=1, oc_slide="Up", oc_lock=true,
                  mb_slots=1, mb_dimples=true, mb_onramp=true,
                  bore=10, preset="openGrid standard", socket_height=14,
                  clearance=0.4, major_override=0, profile="Trapezoidal") {
    union() {
        mount(mount_system=mount_system, board_type=board_type, snap_shape=snap_shape,
              oc_slots=oc_slots, oc_slide=oc_slide, oc_lock=oc_lock,
              mb_slots=mb_slots, mb_dimples=mb_dimples, mb_onramp=mb_onramp);
        down(0.01) threaded_socket(bore=bore, preset=preset, height=socket_height+0.01,
                        clearance=clearance, major_override=major_override, profile=profile);
    }
}

module ring_nut(bore=10, preset="openGrid standard", height=8,
                clearance=0.4, major_override=0, grip="Flats", profile="Trapezoidal") {
    nut_plug(bore=bore, preset=preset, height=height,
             clearance=clearance, major_override=major_override, grip=grip, profile=profile);
}
