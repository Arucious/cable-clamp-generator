use <opengrid_snap_lib.scad>
include <opengrid_base.scad>
include <BOSL2/std.scad>

// In-plane clear footprint (mm) the socket must fit within, per mount.
function mount_face_clear_xy(mount_system, mb_slots=1, oc_slots=1) =
    mount_system == "Multiboard" ? mb_slots * 25 :
    mount_system == "openConnect" ? max(OG_SNAP_WIDTH, oc_slots*OG_SNAP_WIDTH) :
    OG_SNAP_WIDTH;

// How far the attachment extends into -z (informational / asserts).
function mount_height_below(mount_system, board_type="Lite") =
    mount_system == "openGrid snap"
        ? (board_type == "Full" ? OG_STANDARD_THICKNESS : OG_LITE_THICKNESS)
        : 6.5;

// Build the board-attachment in z<=0; mating face is the z=0 plane (normal +z).
module mount(mount_system, board_type="Lite", snap_shape="Symmetric",
             oc_slots=1, oc_slide="Up", oc_lock=true,
             mb_slots=1, mb_dimples=true, mb_onramp=true) {
    if (mount_system == "openGrid snap") {
        th = (board_type == "Full") ? OG_STANDARD_THICKNESS : OG_LITE_THICKNESS;
        down(th)
            base_snap(snapbody_cfg = snap_body_cfg(snap_thickness=th, snap_body_shape=snap_shape),
                      disable_features=["snap_nub"]);
    }
    // openConnect + Multiboard backends added in later tasks.
}
