use <opengrid_snap_lib.scad>
use <openconnect_lib.scad>
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
            base_snap(snapbody_cfg = snap_body_cfg(snap_thickness=th, snap_body_shape=snap_shape));
    }
    else if (mount_system == "openConnect") {
        plate_t = 6.5;
        // Slot receiver cavity geometry via openconnect_head(head_type="slot").
        // Using this form (pure linear_extrude+polygon CSG) avoids BOSL2 tag-
        // intersect artefacts that produce non-manifold output with the Manifold
        // render backend.
        //
        // Slot profile dimensions (from ocslot_cfg defaults, side_clearance=0.10):
        //   large_rect_width  = OCHEAD_LARGE_RECT_WIDTH  + 2*0.10 = 17.2
        //   large_rect_height = OCHEAD_LARGE_RECT_HEIGHT + 2*0.10 = 10.8
        //   back_pos_offset   = OCHEAD_BACK_POS_OFFSET             =  0.4
        //   head Y range      = [ -(lrh - lrw/2 - bpo), lrw/2+bpo ] = [-1.8, 9.0]
        _lrw        = OCHEAD_LARGE_RECT_WIDTH  + 0.2;   // = 17.2
        _lrh        = OCHEAD_LARGE_RECT_HEIGHT + 0.2;   // = 10.8
        _head_y_min = -(_lrh - _lrw/2 - OCHEAD_BACK_POS_OFFSET); // = -1.8
        _entry_y    = -OG_SNAP_WIDTH / 2;               // = -12.4 (plate −Y face)
        // Entry channel height: OCHEAD_TOTAL_HEIGHT + slack so it exceeds the
        // actual slot total_height (~2.705 mm) and avoids coplanar face issues.
        _slot_z     = OCHEAD_TOTAL_HEIGHT + 0.3;        // ≈ 2.9 mm
        // Entry channel width must NOT equal _lrw (17.2) — same-width cube faces
        // become coplanar with the head profile and trigger T-junction non-manifold.
        _entry_w    = _lrw + 0.2;                       // = 17.4 mm
        difference() {
            down(plate_t) cuboid([OG_SNAP_WIDTH, OG_SNAP_WIDTH, plate_t], anchor=BOTTOM);
            // T-profile cavity + lock-detent recesses
            down(plate_t)
                openconnect_head(head_type="slot",
                    add_nubs = oc_lock ? "Both" : "",
                    excess_thickness=EPS, anchor=BOTTOM);
            // Slide entry channel: opens at plate −Y face, reaches slot cavity
            translate([0, (_entry_y + _head_y_min) / 2,
                       -plate_t + _slot_z / 2])
                cube([_entry_w, _head_y_min - _entry_y, _slot_z], center=true);
        }
    }
    // Multiboard backend added in later tasks.
}
