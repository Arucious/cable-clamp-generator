// AUTO-GENERATED single-file build (scripts/build_single_file.py).
// Upload THIS file to MakerWorld's Parametric Model Maker. BOSL2 is provided by the
// platform; everything else is inlined below. Edit sources in cable_clamp/ and re-run.

// ===================== customizer parameters (main) =====================
/*
  Cable Clamp Generator (openGrid snap / openConnect / Multiboard)
  Parametric remix for openGrid + Multiboard / Underware cable management.

  Credits:
    openGrid & Multiconnect standards — David D
    Multiboard — Jonathan / Keep Making
    openGrid snap & openConnect OpenSCAD libs — mitufy (CC-BY)
    MultiConnect OpenSCAD (multiconnectBack) — Chris Schneider / cschneid (CC-BY-NC)
    Underware — Hands on Katie & BlackjackDuck
    Original concept "Cable Clamp for OpenGrid / Underware" — MakerWorld user_3607339627 (inspiration)
  License: CC-BY-NC-SA (non-commercial, share-alike, attribution) — inherited from the bundled libraries.
*/

include <BOSL2/std.scad>

// Smooth curves on MakerWorld's renderer (tests override $fn for speed).
$fa = 2; $fs = 0.4;

/* [Mount] */
Mount_System = "openGrid snap"; // [openGrid snap, openConnect, Multiboard]

/* [openGrid snap] */
Board_Type = "Lite"; // [Lite, Full]
Snap_Shape = "Symmetric"; // [Symmetric, Directional]

/* [openConnect] */
OC_Lock = true;

/* [Multiboard] */
MB_Slots = 1; // [1:3]
MB_Dimples = true;
MB_OnRamp = true;

/* [Cable] */
Cable_Bore_Diameter = 10; // [4:0.5:18]

/* [Thread] */
Thread_Preset = "openGrid standard"; // [openGrid standard, Fine, Coarse, Custom]
Thread_Pitch = 3;               // Custom only
Thread_Profile = "Trapezoidal"; // [Trapezoidal, ISO]  (Custom)
Thread_Major_Diameter = 0;      // 0 = auto-scale with bore (Custom override)
Thread_Clearance = 0.4;

/* [Ring Nut] */
Nut_Height = 9;
Nut_Grip = "Flats"; // [Flats, Knurl, Wings]

/* [Output] */
Part = "Body"; // [Body, Ring Nut, Both (preview)]


// ===================== params.scad =====================
// Pure functions: thread-preset resolution and derived dimensions. No customizer vars here.
//
// Mechanism (cable-gland / collet clamp):
//   - the body BARREL is EXTERNALLY threaded and split by the cable channel into fingers;
//   - the RING NUT is a hollow, INTERNALLY-threaded, knurled ring that screws down AROUND the
//     barrel and squeezes the fingers onto the cable.
// `Cable_Bore_Diameter` is the clear cable channel through the split barrel.

OG_SNAP_WIDTH = 24.8;   // openGrid snap footprint (also the ring-OD ceiling for a 1x1 cell)
MIN_WALL      = 0.8;    // OG_MIN_WALL_WIDTH
BARREL_WALL   = 1.6;    // finger wall: cable channel -> barrel thread root
RING_WALL     = 1.6;    // ring wall: internal thread crest -> knurled outer surface
// Functions (not bare constants) so `use <params.scad>` imports them into thread.scad + generator.
// The cable channel sits on a modest floor and meets the finger walls via a generous CONCAVE FILLET
// (an internal gusset) — material added right at the thin finger-to-base connection, on the
// load-bearing inner side. No chunky base, no outer flare.
function barrel_base()   = 1.6;   // modest channel floor joining the halves (mm)
function barrel_fillet() = 3.0;   // internal gusset fillet radius at the finger roots (mm)

function preset_pitch(preset) =
    preset == "Fine"   ? 2 :
    preset == "Coarse" ? 4 :
    /* openGrid standard / Custom default */ 3;

function thread_depth(pitch) = 0.6 * pitch;

// Barrel EXTERNAL thread major (crest) diameter, derived from the cable bore (or overridden).
function thread_major(bore, pitch, major_override=0) =
    major_override > 0 ? major_override : bore + 2 * BARREL_WALL + 2 * thread_depth(pitch);

// Ring-nut OUTER diameter (used for the nut geometry).
function ring_od(bore, pitch, clearance=0.4, major_override=0) =
    thread_major(bore, pitch, major_override) + 2 * clearance + 2 * RING_WALL;

// Radial allowance beyond the barrel thread crest = the ring (wall + clearance). The internal
// fillet/floor adds no outer diameter, so the ring is the binding outer extent.
function outer_allow(clearance) = clearance + RING_WALL;

// The part's overall OUTER diameter (ring OR flare, whichever is wider) — must fit the footprint.
function part_od(bore, pitch, clearance=0.4, major_override=0) =
    thread_major(bore, pitch, major_override) + 2 * outer_allow(clearance);

// Clamp the bore so the WHOLE part (ring and flare) fits within `footprint`; returns the usable bore.
function clamped_bore(bore, footprint, pitch, clearance=0.4, major_override=0) =
    part_od(bore, pitch, clearance, major_override) <= footprint
        ? bore
        : footprint - 2*outer_allow(clearance) - 2*BARREL_WALL - 2*thread_depth(pitch);

// ===================== thread.scad =====================
include <BOSL2/threading.scad>

// Internal/external thread rod, branching on profile.
module _thread_rod(d, l, pitch, profile, internal, slop=0) {
    if (profile == "ISO")
        threaded_rod(d=d, l=l, pitch=pitch, internal=internal,
                     bevel=!internal, $slop=slop, anchor=BOTTOM);
    else  // Trapezoidal (default)
        trapezoidal_threaded_rod(d=d, l=l, pitch=pitch, internal=internal,
                     bevel=!internal, $slop=slop, anchor=BOTTOM);
}

// Body BARREL: an EXTERNALLY-threaded post, split by the cable channel into fingers. Base at z=0.
// The ring nut screws down around this and compresses the fingers onto the cable.
module threaded_socket(bore, preset, height, clearance=0.4, major_override=0, profile="Trapezoidal") {
    p     = preset_pitch(preset);
    major = thread_major(bore, p, major_override);   // external thread crest OD
    difference() {
        _thread_rod(d=major, l=height, pitch=p, profile=profile, internal=false);
        // cable channel: open top + front/back, seated on a modest floor (barrel_base) with a
        // generous concave fillet where it meets the finger walls — an internal gusset that
        // reinforces the thin finger-to-base connection on the load-bearing inner side.
        // Fillet capped at half the channel width so it stays valid for small bores.
        fr = max(0, min(barrel_fillet(), bore/2 - 0.5));
        up(barrel_base()) cuboid([bore, major+2, height], anchor=BOTTOM, rounding=fr, edges=BOTTOM);
    }
}

// RING NUT: a hollow, INTERNALLY-threaded ring with a grip (knurl/flats/wings) on its OUTER
// surface. Threads onto and around the barrel's external thread. `height` is the ring height.
module nut_plug(bore, preset, height, clearance=0.4, major_override=0, grip="Flats", profile="Trapezoidal") {
    p     = preset_pitch(preset);
    major = thread_major(bore, p, major_override);
    ro    = ring_od(bore, p, clearance, major_override);
    difference() {
        _grip(grip, d=ro, h=height);                          // knurled/flats/wings outer body
        // internal thread cavity (+clearance so it spins around the barrel) — goes through = hollow
        up(-0.5) _thread_rod(d=major + 2*clearance, l=height+1, pitch=p,
                             profile=profile, internal=true, slop=clearance);
    }
}

// Grip body of outer diameter `d`, knurled/flats/wings over its FULL height `h`.
module _grip(grip, d, h) {
    // Knurl: truncated-diamond texture — flat-topped diamonds print cleanly and render manifold
    // on the Manifold backend (MakerWorld). ~2mm tiles, 0.45mm deep, spanning the full grip height.
    if (grip == "Knurl")      cyl(d=d, h=h, texture="trunc_diamonds", tex_size=[2,2], tex_depth=0.45, anchor=BOTTOM);
    else if (grip == "Wings") { cuboid([d*1.4, d*0.28, h], rounding=0.6, edges="Z", anchor=BOTTOM); cuboid([d*0.28, d*1.4, h], rounding=0.6, edges="Z", anchor=BOTTOM); }
    else /* Flats */          prismoid(size1=[d,d], size2=[d-1,d-1], h=h, anchor=BOTTOM);
}

// ===================== mount.scad =====================

// In-plane clear footprint (mm) the socket must fit within, per mount.
function mount_face_clear_xy(mount_system, mb_slots=1, oc_slots=1) =
    mount_system == "Multiboard" ? mb_slots * 25 :
    mount_system == "openConnect" ? OG_SNAP_WIDTH :
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
    else if (mount_system == "Multiboard") {
        plate_w = mb_slots * 25;
        plate_h = 25;
        // multiconnectBack: plate at X[0..w], Y[-6.5..0], Z[0..h], item-face at Y=0.
        // Map to our contract: rotate +Y -> +Z (front face onto z=0 plane, body+slots into -z),
        // and recenter in X so the socket sits at the origin.
        translate([-plate_w/2, 0, 0]) rotate([90, 0, 0])
            multiconnectBack(backWidth=plate_w, backHeight=plate_h, distanceBetweenSlots=25,
                             dimples=mb_dimples, onRamp=mb_onramp);
    }
}

// ===================== clamp.scad =====================

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

// ===================== opengrid_base.scad =====================

EPS = 0.005;
OG_TILE_SIZE = 28;
OG_STANDARD_THICKNESS = 6.8;
OG_LITE_THICKNESS = 4;
OG_LITE_BASIC_THICKNESS = 3.4;

OG_SNAP_CORNER_OUTER_DIAGONAL = 2.7 + 1 / sqrt(2);
OG_SNAP_CORNER_CHAMFER = OG_SNAP_CORNER_OUTER_DIAGONAL * sqrt(2);
OG_SNAP_CORNER_INNER_DIAGONAL = OG_SNAP_WIDTH * sqrt(2) / 2 - OG_SNAP_CORNER_OUTER_DIAGONAL;
OG_SNAP_TEXT_FONT = "Merriweather Sans:style=Bold";
OG_SNAP_EMOJI_FONT = "Noto Emoji";
OG_SNAP_BLUNT_TEXT = "🔓";
OG_SNAP_DIRECTIONAL_ARROW_TEXT = "🔺";

OG_SNAP_THREADS_PROFILE = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];
OG_SNAP_THREADS_DIAMETER = 16;
OG_SNAP_THREADS_CLEARANCE = 0.5;
OG_SNAP_THREADS_COMPATIBILITY_ANGLE = 53.5;

OG_SNAP_THREADS_PITCH = 3;
OG_SNAP_THREADS_SIDE_OFFSET = 1.4;
OG_THREADS_CONNECT_OFFSET = 1.5;
OG_MIN_WALL_WIDTH = 0.8;

OG_SNAP_TEXT_SIZE = 4;
OG_GADGET_TEXT_SIZES = [OG_SNAP_TEXT_SIZE, OG_SNAP_TEXT_SIZE];
OG_GADGET_TEXT_FONTS = [OG_SNAP_EMOJI_FONT, OG_SNAP_TEXT_FONT];
OG_GADGET_TEXT_FILLS = [true, false];
OG_GADGET_TEXT_POSITIONS = [[2.4, 0], [-2.4, 0]];

OG_SNAP_TEXT_SIZES = [OG_SNAP_TEXT_SIZE, OG_SNAP_TEXT_SIZE, 3.6];
OG_SNAP_TEXT_FONTS = [OG_SNAP_EMOJI_FONT, OG_SNAP_TEXT_FONT, OG_SNAP_EMOJI_FONT];
OG_SNAP_TEXT_FILLS = [true, false, true];

OCHEAD_BOTTOM_HEIGHT = 0.6;
OCHEAD_TOP_HEIGHT = 0.6;
OCHEAD_MIDDLE_HEIGHT = 1.4;
OCHEAD_LARGE_RECT_WIDTH = 17;
OCHEAD_LARGE_RECT_HEIGHT = 10.6;
OCHEAD_LARGE_RECT_CHAMFER = 4;

OCHEAD_NUB_TO_TOP_DISTANCE = 7.2;
OCHEAD_NUB_DEPTH = 0.6;
OCHEAD_NUB_TIP_HEIGHT = 1.2;
OCHEAD_NUB_FILLET = 0.8;

OCHEAD_BACK_POS_OFFSET = 0.4;
OCHEAD_TOTAL_HEIGHT = OCHEAD_TOP_HEIGHT + OCHEAD_MIDDLE_HEIGHT + OCHEAD_BOTTOM_HEIGHT;
OCHEAD_MIDDLE_TO_BOTTOM = OCHEAD_LARGE_RECT_HEIGHT - OCHEAD_LARGE_RECT_WIDTH / 2 - OCHEAD_BACK_POS_OFFSET;

OCSLOT_MOVE_DISTANCE = 10.6;
OCSLOT_ONRAMP_CLEARANCE = 0.8;

// ── Configuration Structs ────────────────────────────────────────────────────

// Helper function to safely merge two structs or a struct and a flat override list
function _flatten_struct(s) = [for (i = [0:len(s) - 1], j = [0:1]) s[i][j]];
function struct_merge(struct_a, struct_b) =
  len(struct_b) == 0 ? struct_a
  : is_string(struct_b[0]) ? struct_set(struct_a, struct_b)
  : struct_set(struct_a, _flatten_struct(struct_b));

function text_cfg(
  texts = [],
  sizes = OG_GADGET_TEXT_SIZES,
  fonts = OG_GADGET_TEXT_FONTS,
  fills = OG_GADGET_TEXT_FILLS,
  pos_offsets = [[0, 0]],
  text_depth = 0.4
) =
  struct_set(
    [], [
      "texts",
      texts,
      "sizes",
      sizes,
      "fonts",
      fonts,
      "fills",
      fills,
      "pos_offsets",
      pos_offsets,
      "text_depth",
      text_depth,
    ]
  );

module snap_text(
  text_cfg = [],
  snapbody_cfg = [],
  anchor = BOTTOM,
  spin = 0,
  orient = UP
) {
  _cfg = struct_merge(text_cfg(), text_cfg);
  _texts = struct_val(_cfg, "texts");
  _sizes = struct_val(_cfg, "sizes");
  _fonts = struct_val(_cfg, "fonts");
  _fills = struct_val(_cfg, "fills");
  _offsets = struct_val(_cfg, "pos_offsets");
  _depth = struct_val(_cfg, "text_depth");

  _text_count = len(_texts);
  attachable(anchor, spin, orient, size=[1, 1, max(_depth, EPS)]) {
    tag_scope() {
      if (_text_count > 0 && _depth > 0)
        down(_depth / 2)
          for (i = [0:_text_count - 1]) {
            if (_texts[i] != "") {
              _size = len(_sizes) > i ? _sizes[i] : _sizes[0];
              _font = len(_fonts) > i ? _fonts[i] : _fonts[0];
              _fill = len(_fills) > i ? _fills[i] : _fills[0];

              _offset = len(_offsets) > i ? _offsets[i] : _offsets[0];
              right(_offset[0]) back(_offset[1])
                  linear_extrude(height=_depth + EPS) if (_fill)
                    fill() text(_texts[i], size=_size, anchor=str("center", CENTER), font=_font);
                  else
                    text(_texts[i], size=_size, anchor=str("center", CENTER), font=_font);
            }
          }
        }
    children();
  }
}

// ── Utility Functions & Modules ──────────────────────────────────────────────

// Returns true if the position [hgrid, vgrid] fits the description.
function is_grid_pos_described(hgrid, vgrid, max_hgrid, max_vgrid, description, except_pos = []) =
  let (
    is_exception = in_list([hgrid, vgrid], except_pos),
    is_stagger = hgrid % 2 == vgrid % 2,
    is_top_row = vgrid == 0,
    is_bottom_row = vgrid == max_vgrid - 1,
    is_left_column = hgrid == 0,
    is_right_column = hgrid == max_hgrid - 1,
    is_edge_row = is_top_row || is_bottom_row,
    is_edge_column = is_left_column || is_right_column,
    is_corner = is_edge_row && is_edge_column,
    is_top_corner = is_corner && is_top_row,
    is_bottom_corner = is_corner && is_bottom_row,
    matches_pattern = description == "All" || (description == "Staggered" && is_stagger) || (description == "Corners" && is_corner) || (description == "Top Corners" && is_top_corner) || (description == "Bottom Corners" && is_bottom_corner) || (description == "Edge Rows" && is_edge_row) || (description == "Edge Columns" && is_edge_column)
  ) !is_exception && matches_pattern;

// Returns true if the footprint at cp lies fully within limit_region.
function is_pos_shape_in_region(cp, footprint, limit_region) =
  let (
    result = [for (i = footprint) point_in_region(cp + i, limit_region) >= 0]
  ) !in_list(list=result, val=false);

// Conditionally flips children along the given axis. If copy=true, keep the original.
module conditional_flip(axis = "X", coordinate = 0, copy = false, condition) {
  if (condition) {
    if (axis == "X")
      xflip(x=coordinate) children();
    else if (axis == "Y")
      yflip(y=coordinate) children();
    else if (axis == "Z")
      zflip(z=coordinate) children();
    if (copy)
      children();
  }
  else
    children();
}

// Conditionally cuts children to the given half-space along v.
module conditional_half(v = LEFT, pos_offset = 0, mask_size = 100, condition) {
  if (condition) {
    if (v == LEFT || v == RIGHT)
      half_of(v=v, cp=[pos_offset, 0, 0], s=mask_size) tag_scope() children();
    else if (v == FRONT || v == BACK)
      half_of(v=v, cp=[0, pos_offset, 0], s=mask_size) tag_scope() children();
    else if (v == TOP || v == BOTTOM)
      half_of(v=v, cp=[0, 0, pos_offset], s=mask_size) tag_scope() children();
    else
      half_of(v, cp=pos_offset == 0 ? [0, 0, 0] : pos_offset, s=mask_size) tag_scope() children();
  }
  else
    children();
}

module conditional_fold(body_thickness, fold_position = 0, fold_gap_width = 0.4, fold_gap_height = 0.2, fold_sliceoff = 0, mask_size = 100, condition = true) {
  if (condition) {
    back(fold_position) yrot(180) {
        xrot(-90, cp=[0, -fold_position, 0])
          difference() {
            children();
            fwd(fold_position) cuboid([mask_size, mask_size, mask_size], anchor=BACK);
          }
        fwd(fold_gap_width - EPS) up(fold_sliceoff)
            xrot(90, cp=[0, -fold_position, 0])
              difference() {
                children();
                fwd(fold_position + fold_sliceoff)
                  cuboid([mask_size, mask_size, mask_size], anchor=FRONT);
              }
        fwd(fold_gap_width) xrot(-90, cp=[0, -fold_position, 0])
            linear_extrude(fold_gap_width + EPS * 2) difference() {
                projection(cut=true)
                  down(0.01)
                    children();
                fwd(fold_position - fold_gap_height) rect([mask_size, mask_size], anchor=FRONT);
                fwd(fold_position) rect([mask_size, mask_size], anchor=BACK);
              }
      }
  }
  else
    children();
}

// ===================== opengrid_threads_lib.scad =====================
/*
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/


function threads_cfg(
  threads_type = "Blunt",
  threads_diameter = OG_SNAP_THREADS_DIAMETER,
  threads_clearance = OG_SNAP_THREADS_CLEARANCE,
  threads_pitch = OG_SNAP_THREADS_PITCH,
  threads_top_bevel = 0.5,
  threads_bottom_bevel_standard = 2,
  threads_bottom_bevel_lite = 1.2,
  threads_offset_angle = 0,
  threads_blunt_cutoff = true
) =
  struct_set(
    [], [
      "threads_type",
      threads_type,
      "threads_diameter",
      threads_diameter,
      "threads_clearance",
      threads_clearance,
      "threads_pitch",
      threads_pitch,
      "threads_top_bevel",
      threads_top_bevel,
      "threads_bottom_bevel_standard",
      threads_bottom_bevel_standard,
      "threads_bottom_bevel_lite",
      threads_bottom_bevel_lite,
      "threads_offset_angle",
      threads_offset_angle,
      "threads_blunt_cutoff",
      threads_blunt_cutoff,
    ]
  );

function snap_expand_cfg(
  expand_distance_standard = 0.6,
  expand_distance_lite = 0.4,
  expand_entry_height_standard = 0.4,
  expand_entry_height_lite = 0.4,
  expand_entry_height_blunt = 1,
  expand_end_height_standard = 2,
  expand_end_height_lite = 1.2,
  expand_split_angle = 45
) =
  struct_set(
    [], [
      "expand_distance_standard",
      expand_distance_standard,
      "expand_distance_lite",
      expand_distance_lite,
      "expand_entry_height_standard",
      expand_entry_height_standard,
      "expand_entry_height_lite",
      expand_entry_height_lite,
      "expand_entry_height_blunt",
      expand_entry_height_blunt,
      "expand_end_height_standard",
      expand_end_height_standard,
      "expand_end_height_lite",
      expand_end_height_lite,
      "expand_split_angle",
      expand_split_angle,
    ]
  );

module blunt_threads(threads_height = OG_STANDARD_THICKNESS, top_bevel = 0, bottom_bevel = 0, blunt_ang = 10, threads_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _threads_cfg = struct_merge(threads_cfg(), threads_cfg);
  _diameter = struct_val(_threads_cfg, "threads_diameter") + struct_val(_threads_cfg, "threads_clearance");
  _pitch = struct_val(_threads_cfg, "threads_pitch");
  _top_cutoff = struct_val(_threads_cfg, "threads_blunt_cutoff");

  thread_lead_in_offset = 1.5;
  min_turns = 0.5;
  thread_degrees_per_mm = 360 / _pitch;
  offset_height = min(threads_height - thread_lead_in_offset - bottom_bevel, 0);
  turns = max(0, (threads_height - thread_lead_in_offset - bottom_bevel) / _pitch) + min_turns;

  attachable(anchor, spin, orient, d=_diameter, h=threads_height) {
    tag_scope() down(threads_height / 2) diff() {
          cyl(d=_diameter - 2 + EPS, h=threads_height, anchor=BOTTOM, $fn=256);
          diff("helix_cutoff") {
            zrot(0.25 * thread_degrees_per_mm) up(0.25)
                zrot(-(min_turns * _pitch) * thread_degrees_per_mm) up(-(min_turns * _pitch))
                    zrot(offset_height * thread_degrees_per_mm) up(offset_height)
                        thread_helix(
                          d=_diameter, turns=turns, pitch=_pitch, profile=OG_SNAP_THREADS_PROFILE,
                          anchor=BOTTOM, internal=false, lead_in_ang2=blunt_ang, $fn=256
                        );
            tag("helix_cutoff") up(threads_height + (_diameter + 2) / 2) cube(_diameter + 2, center=true);
          }
          if (_top_cutoff || top_bevel > 0)
            tag("remove") down((_diameter + 2) / 2) cube(_diameter + 2, center=true);
          if (top_bevel > 0)
            force_tag("remove") rotate_extrude() left(_diameter / 2 - top_bevel / 2 + EPS) right_triangle([top_bevel + EPS, top_bevel + EPS], anchor=BOTTOM);
          if (bottom_bevel > 0)
            force_tag("remove") up(threads_height) rotate_extrude() right(_diameter / 2 - bottom_bevel + EPS) right_triangle([bottom_bevel + EPS, bottom_bevel + EPS], anchor=BOTTOM, spin=180);
        }
    children();
  }
}

module snap_threads(threads_height = OG_STANDARD_THICKNESS, threads_cfg = [], text_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _threads_cfg = struct_merge(threads_cfg(), threads_cfg);
  _text_cfg = struct_merge(text_cfg(), text_cfg);
  _threads_type = struct_val(_threads_cfg, "threads_type");
  _threads_offset_angle = struct_val(_threads_cfg, "threads_offset_angle");
  _threads_blunt_cutoff = struct_val(_threads_cfg, "threads_blunt_cutoff");
  _snap_threads_top_bevel = struct_val(_threads_cfg, "threads_top_bevel");
  _snap_threads_bottom_bevel_standard = struct_val(_threads_cfg, "threads_bottom_bevel_standard");
  _snap_threads_bottom_bevel_lite = struct_val(_threads_cfg, "threads_bottom_bevel_lite");
  _threads_diameter = struct_val(_threads_cfg, "threads_diameter");
  _threads_clearance = struct_val(_threads_cfg, "threads_clearance");
  _threads_pitch = struct_val(_threads_cfg, "threads_pitch");
  _snap_threads_bottom_bevel =
    threads_height >= OG_STANDARD_THICKNESS ? _snap_threads_bottom_bevel_standard
    : threads_height >= OG_LITE_BASIC_THICKNESS ? _snap_threads_bottom_bevel_lite
    : 0;

  attachable(anchor, spin, orient, d=_threads_diameter + _threads_clearance, h=threads_height) {
    tag_scope() diff() {
        down(threads_height / 2) zrot(_threads_offset_angle + OG_SNAP_THREADS_COMPATIBILITY_ANGLE) {
            if (_threads_type == "Blunt")
              blunt_threads(threads_height=threads_height, threads_cfg=_threads_cfg);
            else
              generic_threaded_rod(d=_threads_diameter + _threads_clearance, l=threads_height, pitch=_threads_pitch, profile=OG_SNAP_THREADS_PROFILE, bevel1=_snap_threads_top_bevel, bevel2=_snap_threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
          }
        if (struct_val(_text_cfg, "text_depth") > 0)
          up(threads_height / 2 - EPS)
            tag("remove") snap_text(text_cfg=_text_cfg, anchor=TOP);
      }

    children();
  }
}
module expanding_threads(threads_height = OG_STANDARD_THICKNESS, threads_cfg = [], text_cfg = [], expand_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _expand_cfg = struct_merge(snap_expand_cfg(), expand_cfg);
  _is_standard = threads_height >= OG_STANDARD_THICKNESS;

  _threads_cfg = struct_merge(threads_cfg(), threads_cfg);
  _threads_type = struct_val(_threads_cfg, "threads_type");
  _threads_pitch = struct_val(_threads_cfg, "threads_pitch");

  _expand_distance_raw = _is_standard ? struct_val(_expand_cfg, "expand_distance_standard") : struct_val(_expand_cfg, "expand_distance_lite");
  _expand_distance = max(0, _expand_distance_raw);
  _entry_height = _threads_type == "Blunt" ? struct_val(_expand_cfg, "expand_entry_height_blunt") : (_is_standard ? struct_val(_expand_cfg, "expand_entry_height_standard") : struct_val(_expand_cfg, "expand_entry_height_lite"));
  _end_height = _is_standard ? struct_val(_expand_cfg, "expand_end_height_standard") : struct_val(_expand_cfg, "expand_end_height_lite");
  _expand_split_angle = struct_val(_expand_cfg, "expand_split_angle");

  expand_distance_step = 0.05;
  transition_height = threads_height - _entry_height - _end_height;
  expand_segment_count = _expand_distance > 0 ? ceil(_expand_distance / expand_distance_step) : 0;
  expand_height_step = expand_segment_count > 0 ? transition_height / expand_segment_count : transition_height;
  thread_degrees_per_mm = 360 / _threads_pitch;

  _no_text_cfg = ["text_depth", 0];
  _no_cutoff_cfg = ["threads_blunt_cutoff", false];
  _no_top_bevel_cfg = ["threads_top_bevel", 0];
  _no_bottom_bevel_cfg = ["threads_bottom_bevel_standard", 0, "threads_bottom_bevel_lite", 0];

  _diameter = struct_val(_threads_cfg, "threads_diameter") + struct_val(_threads_cfg, "threads_clearance");

  render() {
    attachable(anchor, spin, orient, d=_diameter, h=threads_height) {
      tag_scope() down(threads_height / 2) {
          if (_entry_height > 0)
            snap_threads(threads_height=_entry_height + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg, _no_bottom_bevel_cfg)));
          if (expand_segment_count > 0) {
            for (a = [0:expand_segment_count - 1]) {
              aseg_position = _entry_height + expand_height_step * a;
              aseg_expansion_distance = min(_expand_distance, expand_distance_step * (a + 1));
              zrot(-_expand_split_angle)
                partition(spread=-aseg_expansion_distance - EPS, cutpath="flat", $slop=aseg_expansion_distance / 2)
                  zrot(_expand_split_angle) up(aseg_position) zrot(aseg_position * thread_degrees_per_mm)
                        snap_threads(threads_height=expand_height_step + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg, _no_bottom_bevel_cfg)));
            }
          }
          else if (transition_height > 0)
            up(_entry_height) zrot(_entry_height * thread_degrees_per_mm)
              snap_threads(threads_height=transition_height + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg, _no_bottom_bevel_cfg)));
          if (_end_height > 0) {
            if (_expand_distance > 0)
              zrot(-_expand_split_angle)
                partition(spread=-_expand_distance - EPS, cutpath="flat", $slop=_expand_distance / 2)
                  zrot(_expand_split_angle) up(_entry_height + transition_height) zrot((_entry_height + transition_height) * thread_degrees_per_mm)
                        snap_threads(threads_height=max(_end_height, 0) + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg)));
            else
              up(_entry_height + transition_height) zrot((_entry_height + transition_height) * thread_degrees_per_mm)
                    snap_threads(threads_height=max(_end_height, 0) + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg)));
          }
        }
      children();
    }
  }
}

// ===================== opengrid_snap_lib.scad =====================
/*
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/


function snap_body_cfg(
  snap_width = OG_SNAP_WIDTH,
  snap_height = OG_SNAP_WIDTH,
  snap_thickness = OG_STANDARD_THICKNESS,
  snap_body_shape = "Directional"
) =
  struct_set(
    [], [
      "snap_width",
      snap_width,
      "snap_height",
      snap_height,
      "snap_thickness",
      snap_thickness,
      "snap_body_shape",
      snap_body_shape,
    ]
  );

function snap_corner_cfg(
  directional_corner_fillet_radius = 1.5,
  snap_corner_edge_height = 1.5,
  snap_body_top_corner_extrude = 1.1,
  snap_body_bottom_corner_extrude = 0.6
) =
  struct_set(
    [], [
      "directional_corner_fillet_radius",
      directional_corner_fillet_radius,
      "snap_corner_edge_height",
      snap_corner_edge_height,
      "snap_body_top_corner_extrude",
      snap_body_top_corner_extrude,
      "snap_body_bottom_corner_extrude",
      snap_body_bottom_corner_extrude,
    ]
  );

function snap_cut_cfg(
  cut_width_inset = 6.2,
  bottom_cut_thickness = 0.6,
  bottom_cut_offset_to_top = 0.6,
  bottom_cut_offset_to_edge = 0.7,
  side_cut_thickness = 0.4,
  side_cut_depth = 0.8,
  side_cut_offset_to_top = 0.8,
  directional_slant_height_standard = 3.4,
  directional_slant_height_lite = 1.2,
  directional_slant_depth_standard = 0.8,
  directional_slant_depth_lite = 0.2,
  disable_all_side_cut = false,
  disable_all_bottom_cut = false,
  disable_front_side_cut = false,
  disable_directional_slant = false
) =
  struct_set(
    [], [
      "cut_width_inset",
      cut_width_inset,
      "bottom_cut_thickness",
      bottom_cut_thickness,
      "bottom_cut_offset_to_top",
      bottom_cut_offset_to_top,
      "bottom_cut_offset_to_edge",
      bottom_cut_offset_to_edge,
      "side_cut_thickness",
      side_cut_thickness,
      "side_cut_depth",
      side_cut_depth,
      "side_cut_offset_to_top",
      side_cut_offset_to_top,
      "directional_slant_height_standard",
      directional_slant_height_standard,
      "directional_slant_height_lite",
      directional_slant_height_lite,
      "directional_slant_depth_standard",
      directional_slant_depth_standard,
      "directional_slant_depth_lite",
      directional_slant_depth_lite,
      "disable_all_side_cut",
      disable_all_side_cut,
      "disable_all_bottom_cut",
      disable_all_bottom_cut,
      "disable_front_side_cut",
      disable_front_side_cut,
      "disable_directional_slant",
      disable_directional_slant,
    ]
  );

function snap_nub_cfg(
  basic_nub_width_inset = 7,
  basic_nub_depth = 0.4,
  basic_nub_width_tip_taper = 4,
  basic_nub_top_angle = 35,
  basic_nub_bottom_angle = 35,
  basic_nub_fillet_radius = 15,
  basic_nub_height_standard = 2,
  basic_nub_height_lite = 1.8,
  directional_nub_width_inset = 5,
  directional_nub_depth = 0.8,
  directional_nub_width_tip_taper = 1.6,
  directional_nub_top_angle = 35,
  directional_nub_height_standard = 4,
  directional_nub_height_lite = 2.4,
  directional_nub_bottom_angle_standard = 35,
  directional_nub_bottom_angle_lite = 45,
  directional_nub_fillet_radius = 2.8,
  antidirect_nub_height_standard = 2,
  antidirect_nub_height_lite = 1.4,
  nub_offset_to_top = 1.4
) =
  struct_set(
    [], [
      "basic_nub_width_inset",
      basic_nub_width_inset,
      "basic_nub_depth",
      basic_nub_depth,
      "basic_nub_width_tip_taper",
      basic_nub_width_tip_taper,
      "basic_nub_top_angle",
      basic_nub_top_angle,
      "basic_nub_bottom_angle",
      basic_nub_bottom_angle,
      "basic_nub_fillet_radius",
      basic_nub_fillet_radius,
      "basic_nub_height_standard",
      basic_nub_height_standard,
      "basic_nub_height_lite",
      basic_nub_height_lite,
      "directional_nub_width_inset",
      directional_nub_width_inset,
      "directional_nub_depth",
      directional_nub_depth,
      "directional_nub_width_tip_taper",
      directional_nub_width_tip_taper,
      "directional_nub_top_angle",
      directional_nub_top_angle,
      "directional_nub_height_standard",
      directional_nub_height_standard,
      "directional_nub_height_lite",
      directional_nub_height_lite,
      "directional_nub_bottom_angle_standard",
      directional_nub_bottom_angle_standard,
      "directional_nub_bottom_angle_lite",
      directional_nub_bottom_angle_lite,
      "directional_nub_fillet_radius",
      directional_nub_fillet_radius,
      "antidirect_nub_height_standard",
      antidirect_nub_height_standard,
      "antidirect_nub_height_lite",
      antidirect_nub_height_lite,
      "nub_offset_to_top",
      nub_offset_to_top,
    ]
  );

function snap_notch_cfg(
  notch_width = 5,
  notch_surface_inset = 1,
  notch_gap_inset = 1.8,
  notch_surface_height_standard = 1.2,
  notch_surface_height_lite = 0.8,
  notch_gap_height_standard = 1,
  notch_gap_height_lite = 0.6
) =
  struct_set(
    [], [
      "notch_width",
      notch_width,
      "notch_surface_inset",
      notch_surface_inset,
      "notch_gap_inset",
      notch_gap_inset,
      "notch_surface_height_standard",
      notch_surface_height_standard,
      "notch_surface_height_lite",
      notch_surface_height_lite,
      "notch_gap_height_standard",
      notch_gap_height_standard,
      "notch_gap_height_lite",
      notch_gap_height_lite,
    ]
  );

function snap_spring_cfg(
  spring_thickness = 1.26,
  spring_to_center_thickness = 0.84,
  spring_gap = 0.42,
  spring_face_chamfer = 0.2
) =
  struct_set(
    [], [
      "spring_thickness",
      spring_thickness,
      "spring_to_center_thickness",
      spring_to_center_thickness,
      "spring_gap",
      spring_gap,
      "spring_face_chamfer",
      spring_face_chamfer,
    ]
  );

module snap_corner(snapbody_cfg = [], snapcorner_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _corner_cfg = struct_merge(snap_corner_cfg(), snapcorner_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _directional_corner_fillet_radius = struct_val(_corner_cfg, "directional_corner_fillet_radius");
  _snap_corner_edge_height = struct_val(_corner_cfg, "snap_corner_edge_height");
  _snap_body_top_corner_extrude = struct_val(_corner_cfg, "snap_body_top_corner_extrude");
  _snap_body_bottom_corner_extrude = struct_val(_corner_cfg, "snap_body_bottom_corner_extrude");
  up(_snap_thickness / 2 - _snap_corner_edge_height / 2) {
    for (i = [FRONT + LEFT, FRONT + RIGHT, BACK + LEFT, BACK + RIGHT])
      attach(i, BOTTOM, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL - EPS)
        prismoid(size1=[OG_SNAP_CORNER_CHAMFER * sqrt(2), _snap_corner_edge_height], xang=45, yang=[45, 90], h=_snap_body_top_corner_extrude);
  }
  //bottom corners for directional full snaps
  if (_snap_body_shape == "Directional" && _snap_thickness >= OG_STANDARD_THICKNESS) {
    down(_snap_thickness / 2 - _snap_corner_edge_height / 2)
      diff("corner_fillet")
        attach([BACK + LEFT, BACK + RIGHT], BOTTOM, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL - EPS)
          prismoid(size1=[OG_SNAP_CORNER_CHAMFER * sqrt(2), _snap_corner_edge_height], xang=45, yang=[90, 45], h=_snap_body_bottom_corner_extrude)
            tag("corner_fillet") edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=OG_STANDARD_THICKNESS, r=_directional_corner_fillet_radius, $fn=64);
  }
}
module snap_cut(snapbody_cfg = [], snapcut_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _cut_cfg = struct_merge(snap_cut_cfg(), snapcut_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _snap_width = struct_val(_body_cfg, "snap_width");
  _snap_height = struct_val(_body_cfg, "snap_height");

  _cut_width_inset = struct_val(_cut_cfg, "cut_width_inset");
  _bottom_cut_thickness = struct_val(_cut_cfg, "bottom_cut_thickness");
  _bottom_cut_offset_to_top = struct_val(_cut_cfg, "bottom_cut_offset_to_top");
  _bottom_cut_offset_to_edge = struct_val(_cut_cfg, "bottom_cut_offset_to_edge");
  _side_cut_thickness = struct_val(_cut_cfg, "side_cut_thickness");
  _side_cut_depth = struct_val(_cut_cfg, "side_cut_depth");
  _side_cut_offset_to_top = struct_val(_cut_cfg, "side_cut_offset_to_top");
  _directional_slant_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_height_standard") : struct_val(_cut_cfg, "directional_slant_height_lite");
  _directional_slant_depth = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_depth_standard") : struct_val(_cut_cfg, "directional_slant_depth_lite");
  _directional_corner_slant_depth = _directional_slant_depth / sqrt(2);

  _disable_all_side_cut = struct_val(_cut_cfg, "disable_all_side_cut");
  _disable_all_bottom_cut = struct_val(_cut_cfg, "disable_all_bottom_cut");
  _disable_front_side_cut = struct_val(_cut_cfg, "disable_front_side_cut");
  _disable_directional_slant = struct_val(_cut_cfg, "disable_directional_slant");

  for (i = [FRONT, LEFT, RIGHT, BACK]) {
    bottom_cut_length = ((i == LEFT || i == RIGHT) ? _snap_height : _snap_width) - _cut_width_inset * 2;
    bottom_cut_rounding = _snap_body_shape == "Directional" && i == FRONT ? 0 : _bottom_cut_thickness / 2;
    if (!_disable_all_bottom_cut && !(_snap_body_shape == "Directional" && i == BACK)) {
      down(_bottom_cut_offset_to_top)
        attach(i, FRONT, inside=true, shiftout=-_bottom_cut_offset_to_edge)
          cuboid([bottom_cut_length, _bottom_cut_thickness, _snap_thickness], rounding=bottom_cut_rounding, edges="Z", $fn=64);
    }
    if (!_disable_all_side_cut)
      if (i != FRONT || !_disable_front_side_cut)
        down(_side_cut_offset_to_top)
          attach(i, FRONT, align=TOP, inside=true)
            cuboid([bottom_cut_length, _side_cut_depth, _side_cut_thickness]);
  }
  if (_snap_body_shape == "Directional" && !_disable_all_bottom_cut && !_disable_directional_slant)
    down(_snap_thickness / 2 - _directional_slant_height / 2) {
      bottom_cut_length = _snap_width - _cut_width_inset * 2;
      tag_diff("remove", "inner_remove") {
        attach(FRONT, BACK, inside=true, shiftout=-_bottom_cut_offset_to_edge - _bottom_cut_thickness)
          tag("") prismoid(size1=[bottom_cut_length, _directional_slant_depth], size2=[bottom_cut_length, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
        attach(FRONT, BACK, inside=true, shiftout=-_bottom_cut_offset_to_edge)
          tag("inner_remove") prismoid(size1=[bottom_cut_length, _directional_slant_depth], size2=[bottom_cut_length, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
      }
      tag_diff("keep", "inner_remove") {
        attach(FRONT, BACK, inside=true, shiftout=-_bottom_cut_offset_to_edge)
          tag("") prismoid(size1=[bottom_cut_length, _directional_slant_depth], size2=[bottom_cut_length, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
        attach(FRONT, BACK, inside=true)
          tag("inner_remove") prismoid(size1=[_snap_width, _directional_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
      }
    }
  if (_snap_body_shape == "Directional" && !_disable_directional_slant) {
    down(_snap_thickness / 2 - _directional_slant_height / 2) {
      attach(FRONT + LEFT, BACK, inside=true, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL)
        prismoid(size1=[_snap_width, _directional_corner_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_corner_slant_depth / 2], h=_directional_slant_height);
      attach(FRONT + RIGHT, BACK, inside=true, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL)
        prismoid(size1=[_snap_width, _directional_corner_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_corner_slant_depth / 2], h=_directional_slant_height);
      attach(FRONT, BACK, inside=true)
        prismoid(size1=[_snap_width, _directional_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
    }
  }
}
module snap_nub(snapbody_cfg = [], snapnub_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _nub_cfg = struct_merge(snap_nub_cfg(), snapnub_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _snap_width = struct_val(_body_cfg, "snap_width");
  _snap_height = struct_val(_body_cfg, "snap_height");
  _basic_nub_width_inset = struct_val(_nub_cfg, "basic_nub_width_inset");
  _basic_nub_depth = struct_val(_nub_cfg, "basic_nub_depth");
  _basic_nub_width_tip_taper = struct_val(_nub_cfg, "basic_nub_width_tip_taper");
  _basic_nub_top_angle = struct_val(_nub_cfg, "basic_nub_top_angle");
  _basic_nub_bottom_angle = struct_val(_nub_cfg, "basic_nub_bottom_angle");
  _basic_nub_fillet_radius = struct_val(_nub_cfg, "basic_nub_fillet_radius");
  _directional_nub_width_inset = struct_val(_nub_cfg, "directional_nub_width_inset");
  _directional_nub_depth = struct_val(_nub_cfg, "directional_nub_depth");
  _directional_nub_width_tip_taper = struct_val(_nub_cfg, "directional_nub_width_tip_taper");
  _directional_nub_top_angle = struct_val(_nub_cfg, "directional_nub_top_angle");
  _directional_nub_fillet_radius = struct_val(_nub_cfg, "directional_nub_fillet_radius");
  _nub_offset_to_top = struct_val(_nub_cfg, "nub_offset_to_top");

  _basic_nub_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "basic_nub_height_standard") : struct_val(_nub_cfg, "basic_nub_height_lite");
  _directional_nub_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "directional_nub_height_standard") : struct_val(_nub_cfg, "directional_nub_height_lite");
  _antidirect_nub_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "antidirect_nub_height_standard") : struct_val(_nub_cfg, "antidirect_nub_height_lite");
  _directional_nub_bottom_angle = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "directional_nub_bottom_angle_standard") : struct_val(_nub_cfg, "directional_nub_bottom_angle_lite");

  basic_nub_yang = [_basic_nub_top_angle, _basic_nub_bottom_angle];
  directional_nub_yang = [_directional_nub_top_angle, _directional_nub_bottom_angle];

  diff("nub_remove") {
    for (i = [FRONT, LEFT, RIGHT, BACK]) {
      basic_nub_width = ((i == LEFT || i == RIGHT) ? _snap_height : _snap_width) - _basic_nub_width_inset * 2;
      directional_nub_width = ((i == LEFT || i == RIGHT) ? _snap_height : _snap_width) - _directional_nub_width_inset * 2;
      basic_nub_size1 = [basic_nub_width, _basic_nub_height];
      basic_nub_size2 = [basic_nub_width - _basic_nub_width_tip_taper, undef];
      directional_nub_size1 = [directional_nub_width, _directional_nub_height];
      directional_nub_size2 = [directional_nub_width - _directional_nub_width_tip_taper, undef];
      antidirect_nub_size1 = [basic_nub_width, _antidirect_nub_height];
      final_nub_size1 =
        (_snap_body_shape == "Directional" && i == BACK) ? directional_nub_size1
        : (_snap_body_shape == "Directional" && i == FRONT) ? antidirect_nub_size1
        : basic_nub_size1;
      final_nub_size2 =
        (_snap_body_shape == "Directional" && i == BACK) ? directional_nub_size2
        : basic_nub_size2;
      l_nub_yang = (_snap_body_shape == "Directional" && i == BACK) ? directional_nub_yang : basic_nub_yang;
      l_nub_depth = (_snap_body_shape == "Directional" && i == BACK) ? _directional_nub_depth : _basic_nub_depth;
      nub_fillet_radius = (_snap_body_shape == "Directional" && i == BACK) ? _directional_nub_fillet_radius : _basic_nub_fillet_radius;
      attach(i, BOTTOM, align=TOP, inset=_nub_offset_to_top, shiftout=-EPS)
        prismoid(size1=final_nub_size1, size2=final_nub_size2, yang=l_nub_yang, h=l_nub_depth)
          tag("nub_remove") edge_mask([TOP + LEFT, TOP + RIGHT])
              rounding_edge_mask(l=8, r=nub_fillet_radius, $fn=64);
    }
    attach(BOTTOM, TOP)
      tag("nub_remove") cuboid([_snap_width * 2, _snap_height * 2, _snap_thickness * 2]);
  }
}
module snap_uninstall_notch(snapbody_cfg = [], snapnotch_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _notch_cfg = struct_merge(snap_notch_cfg(), snapnotch_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _notch_width = struct_val(_notch_cfg, "notch_width");
  _notch_surface_inset = struct_val(_notch_cfg, "notch_surface_inset");
  _notch_gap_inset = struct_val(_notch_cfg, "notch_gap_inset");
  _notch_surface_height_standard = struct_val(_notch_cfg, "notch_surface_height_standard");
  _notch_surface_height_lite = struct_val(_notch_cfg, "notch_surface_height_lite");
  _notch_gap_height_standard = struct_val(_notch_cfg, "notch_gap_height_standard");
  _notch_gap_height_lite = struct_val(_notch_cfg, "notch_gap_height_lite");
  _notch_surface_height =
    _snap_thickness >= OG_STANDARD_THICKNESS ? _notch_surface_height_standard
    : _notch_surface_height_lite;
  _notch_gap_height =
    _snap_thickness >= OG_STANDARD_THICKNESS ? _notch_gap_height_standard
    : _notch_gap_height_lite;
  if (_notch_width > 0 && _notch_surface_inset > 0 && _notch_surface_height > 0)
    cuboid([_notch_width, _notch_surface_inset, _notch_surface_height], anchor=anchor, spin=spin, orient=orient)
      attach(BOTTOM, TOP, align=FRONT)
        cuboid([_notch_width, _notch_gap_inset, _notch_gap_height])
          //cut off remaining snap extrusion
          attach(FRONT, BACK, align=TOP)
            cuboid([_notch_width, _notch_gap_inset, _notch_gap_height]);
}
module expanding_spring(snapbody_cfg = [], spring_cfg = [], snapcorner_cfg = [], snapcut_cfg = [], threads_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _spring_cfg = struct_merge(snap_spring_cfg(), spring_cfg);
  _corner_cfg = struct_merge(snap_corner_cfg(), snapcorner_cfg);
  _cut_cfg = struct_merge(snap_cut_cfg(), snapcut_cfg);
  _threads_cfg = struct_merge(threads_cfg(), threads_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _disable_directional_slant = struct_val(_cut_cfg, "disable_directional_slant");
  bottom_type_back = _snap_body_shape == "Directional" && _snap_thickness >= OG_STANDARD_THICKNESS ? "Corners" : "None";
  bottom_type_front = _snap_body_shape == "Directional" && !_disable_directional_slant ? "Slant" : "None";

  for (i = [0:1]) {
    bottom_type = i == 0 ? bottom_type_back : bottom_type_front;
    zrot(i * 180) {
      // spring-specific params
      _spring_thickness = struct_val(_spring_cfg, "spring_thickness");
      _spring_to_center_thickness = struct_val(_spring_cfg, "spring_to_center_thickness");
      _spring_gap = struct_val(_spring_cfg, "spring_gap");
      _spring_face_chamfer = struct_val(_spring_cfg, "spring_face_chamfer");
      // corner geometry
      _snap_corner_edge_height = struct_val(_corner_cfg, "snap_corner_edge_height");
      _snap_body_top_corner_extrude = struct_val(_corner_cfg, "snap_body_top_corner_extrude");
      _snap_body_bottom_corner_extrude = struct_val(_corner_cfg, "snap_body_bottom_corner_extrude");
      // slant geometry
      _directional_slant_depth =
        _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_depth_standard")
        : struct_val(_cut_cfg, "directional_slant_depth_lite");
      _directional_slant_height =
        _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_height_standard")
        : struct_val(_cut_cfg, "directional_slant_height_lite");
      _threads_negative_diameter = struct_val(_threads_cfg, "threads_diameter") + struct_val(_threads_cfg, "threads_clearance");
      _snap_body_corner_inner_diagonal = OG_SNAP_CORNER_INNER_DIAGONAL;

      // gap_length: minimum reach to clear the thread hole center from the spring wall
      gap_length = _threads_negative_diameter / 2 + _spring_to_center_thickness;
      gap_top_profile = [[-_spring_gap / 2, 0], [-_spring_gap / 2, gap_length], [_spring_gap / 2, gap_length], [_spring_gap / 2, 0]];
      gap_top_profile_rounded = round_corners(gap_top_profile, method="circle", radius=[0, _spring_gap / 2, _spring_gap / 2, 0], $fn=64);
      middle_gap_side_profile_none = [
        [0, 0],
        [0, _snap_thickness],
        [gap_length, _snap_thickness],
        [gap_length, _snap_corner_edge_height],
        [gap_length + _snap_body_top_corner_extrude, _snap_corner_edge_height - _snap_body_top_corner_extrude],
        [gap_length + _snap_body_top_corner_extrude, 0],
      ];
      middle_gap_side_profile_slant = [
        [0, 0],
        [0, _snap_thickness],
        [gap_length - _directional_slant_depth, _snap_thickness],
        [gap_length, _snap_thickness - _directional_slant_height],
        [gap_length, _snap_corner_edge_height],
        [gap_length + _snap_body_top_corner_extrude, _snap_corner_edge_height - _snap_body_top_corner_extrude],
        [gap_length + _snap_body_top_corner_extrude, 0],
      ];
      middle_gap_side_profile_corner = [
        [0, 0],
        [0, _snap_thickness],
        [gap_length + _snap_body_bottom_corner_extrude, _snap_thickness],
        [gap_length + _snap_body_bottom_corner_extrude, _snap_thickness - (_snap_corner_edge_height - _snap_body_bottom_corner_extrude)],
        [gap_length, _snap_thickness - _snap_corner_edge_height],
        [gap_length, _snap_corner_edge_height],
        [gap_length + _snap_body_top_corner_extrude, _snap_corner_edge_height - _snap_body_top_corner_extrude],
        [gap_length + _snap_body_top_corner_extrude, 0],
      ];
      middle_gap_side_profile =
        bottom_type == "None" ? middle_gap_side_profile_none
        : bottom_type == "Slant" ? middle_gap_side_profile_slant
        : middle_gap_side_profile_corner;
      middle_gap_bottom_to_side =
        bottom_type == "None" ? 0
        : bottom_type == "Slant" ? -_directional_slant_depth
        : _snap_body_bottom_corner_extrude;

      //middle gap main body
      back(_snap_body_corner_inner_diagonal - gap_length - _spring_thickness) zrot(90) xrot(90)
            offset_sweep(middle_gap_side_profile, height=_spring_gap + EPS, bottom=os_smooth(joint=_spring_gap / 2), top=os_smooth(joint=_spring_gap / 2), anchor="zcenter");
      //middle gap bottom chamfer
      up(_snap_thickness + EPS / 2)
        yrot(180) back(_snap_body_corner_inner_diagonal - gap_length - _spring_thickness + middle_gap_bottom_to_side)
            offset_sweep(gap_top_profile_rounded, height=_spring_face_chamfer + EPS, bottom=os_chamfer(width=-_spring_face_chamfer));
      //middle gap top chamfer
      down(EPS / 2)
        back(_snap_body_corner_inner_diagonal - gap_length - _spring_thickness + _snap_body_top_corner_extrude)
          offset_sweep(gap_top_profile_rounded, height=_spring_face_chamfer + EPS, bottom=os_chamfer(width=-_spring_face_chamfer));
      down(EPS / 2)
        yflip_copy() right(_spring_thickness + _spring_gap) back(gap_length + _threads_negative_diameter / 2 + _spring_to_center_thickness) zrot(180)
                offset_sweep(gap_top_profile_rounded, height=_snap_thickness + EPS, bottom=os_chamfer(width=-_spring_face_chamfer), top=os_chamfer(width=-_spring_face_chamfer));
    }
  }
}

module base_snap(snapbody_cfg = [], disable_features = [], snapcorner_cfg = [], snapnub_cfg = [], snapnotch_cfg = [], snapcut_cfg = [], text_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _snap_width = struct_val(_body_cfg, "snap_width");
  _snap_height = struct_val(_body_cfg, "snap_height");
  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  attachable(anchor, spin, orient, size=[_snap_width, _snap_height, _snap_thickness]) {
    tag_scope() diff()
        cuboid([_snap_width, _snap_height, _snap_thickness], chamfer=OG_SNAP_CORNER_CHAMFER, edges="Z") {
          if (!in_list(list=disable_features, val="snap_corner"))
            snap_corner(snapbody_cfg=snapbody_cfg, snapcorner_cfg=snapcorner_cfg);
          if (!in_list(list=disable_features, val="snap_nub"))
            snap_nub(snapbody_cfg=snapbody_cfg, snapnub_cfg=snapnub_cfg);
          if (!in_list(list=disable_features, val="snap_cut"))
            snap_cut(snapbody_cfg=snapbody_cfg, snapcut_cfg=struct_set(snapcut_cfg, ["disable_front_side_cut", !in_list(list=disable_features, val="snap_uninstall_notch")]));
          if (!in_list(list=disable_features, val="snap_uninstall_notch"))
            attach(TOP, TOP, align=FRONT, shiftout=EPS, inside=true)
              snap_uninstall_notch(snapbody_cfg=snapbody_cfg, snapnotch_cfg=snapnotch_cfg);
          if (!in_list(list=disable_features, val="snap_text"))
            attach(BOTTOM, TOP, inside=true)
              snap_text(text_cfg=text_cfg, snapbody_cfg=snapbody_cfg);
        }
    children();
  }
}

module expanding_snap(
  snapbody_cfg = [],
  snapcorner_cfg = [],
  snapnub_cfg = [],
  snapcut_cfg = [],
  snapnotch_cfg = [],
  text_cfg = [],
  spring_cfg = [],
  expand_cfg = [],
  threads_cfg = [],
  add_expand_distance_text = false,
  center_position_offset = [0, 0]
) {
  _snap_thickness = struct_val(snapbody_cfg, "snap_thickness", OG_STANDARD_THICKNESS);
  _snap_width = struct_val(snapbody_cfg, "snap_width", OG_SNAP_WIDTH);
  expand_cut_cfg = struct_set(snapcut_cfg, ["disable_all_side_cut", true, "disable_all_bottom_cut", true]);
  _expand_cfg = struct_merge(snap_expand_cfg(), expand_cfg);
  _expand_distance = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_expand_cfg, "expand_distance_standard") : struct_val(_expand_cfg, "expand_distance_lite");
  _expand_split_angle = struct_val(_expand_cfg, "expand_split_angle");
  _texts = struct_val(text_cfg, "texts", []);
  _sizes = struct_val(text_cfg, "sizes", []);
  _fonts = struct_val(text_cfg, "fonts", []);
  _pos_offsets = struct_val(text_cfg, "pos_offsets", []);

  expand_text_cfg =
    add_expand_distance_text ? struct_set(
        text_cfg, [
          "texts",
          concat(_texts, [str(_expand_distance)]),
          "sizes",
          concat(_sizes, [3.2]),
          "fonts",
          concat(_fonts, [OG_SNAP_TEXT_FONT]),
          "pos_offsets",
          concat(_pos_offsets, [[0, -(_snap_width / 2 - 3.2)]]),
        ]
      )
    : text_cfg;
  tag_scope() diff() {
      up(_snap_thickness) yrot(180)
          base_snap(
            snapbody_cfg=snapbody_cfg, snapcorner_cfg=snapcorner_cfg, snapnub_cfg=snapnub_cfg,
            snapcut_cfg=expand_cut_cfg, snapnotch_cfg=snapnotch_cfg, text_cfg=expand_text_cfg
          );
      left(center_position_offset[0]) back(center_position_offset[1]) {
        down(EPS / 2) tag("remove") expanding_threads(
              threads_height=_snap_thickness,
              expand_cfg=expand_cfg, threads_cfg=threads_cfg
            );
        zrot(_expand_split_angle)
          tag("remove") expanding_spring(
              snapbody_cfg=snapbody_cfg, spring_cfg=spring_cfg, snapcorner_cfg=snapcorner_cfg,
              snapcut_cfg=snapcut_cfg, threads_cfg=threads_cfg
            );
      }
    }
}

// ===================== openconnect_lib.scad =====================
/*
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Inspired by David's multiConnect: https://www.printables.com/model/1008622-multiconnect-for-multiboard-v2-modeling-files.
*/

function ochead_cfg(
  bottom_height = OCHEAD_BOTTOM_HEIGHT,
  top_height = OCHEAD_TOP_HEIGHT,
  middle_height = OCHEAD_MIDDLE_HEIGHT,
  large_rect_width = OCHEAD_LARGE_RECT_WIDTH,
  large_rect_height = OCHEAD_LARGE_RECT_HEIGHT,
  large_rect_chamfer = OCHEAD_LARGE_RECT_CHAMFER,
  nub_to_top_distance = OCHEAD_NUB_TO_TOP_DISTANCE,
  nub_depth = OCHEAD_NUB_DEPTH,
  nub_tip_height = OCHEAD_NUB_TIP_HEIGHT,
  nub_fillet = OCHEAD_NUB_FILLET,
  back_pos_offset = OCHEAD_BACK_POS_OFFSET
) =
  let (
    small_rect_width = large_rect_width - middle_height * 2,
    small_rect_height = large_rect_height - middle_height,
    small_rect_chamfer = large_rect_chamfer - middle_height + ang_adj_to_opp(45 / 2, middle_height),
    total_height = top_height + middle_height + bottom_height,
    middle_to_bottom = large_rect_height - large_rect_width / 2 - back_pos_offset,
    bottom_profile = back(large_rect_width / 2 + back_pos_offset, rect([large_rect_width, large_rect_height], chamfer=[large_rect_chamfer, large_rect_chamfer, 0, 0], anchor=BACK)),
    top_profile = back(small_rect_width / 2 + back_pos_offset, rect([small_rect_width, small_rect_height], chamfer=[small_rect_chamfer, small_rect_chamfer, 0, 0], anchor=BACK))
  ) struct_set(
    [], [
      "bottom_height",
      bottom_height,
      "top_height",
      top_height,
      "middle_height",
      middle_height,
      "large_rect_width",
      large_rect_width,
      "large_rect_height",
      large_rect_height,
      "large_rect_chamfer",
      large_rect_chamfer,
      "nub_to_top_distance",
      nub_to_top_distance,
      "nub_depth",
      nub_depth,
      "nub_tip_height",
      nub_tip_height,
      "nub_fillet",
      nub_fillet,
      "back_pos_offset",
      back_pos_offset,
      "small_rect_width",
      small_rect_width,
      "small_rect_height",
      small_rect_height,
      "small_rect_chamfer",
      small_rect_chamfer,
      "total_height",
      total_height,
      "middle_to_bottom",
      middle_to_bottom,
      "bottom_profile",
      bottom_profile,
      "top_profile",
      top_profile,
    ]
  );

function ocslot_cfg(
  edge_feature = "Both",
  edge_bridge_min_w = 0.8,
  edge_wall_min_w = 0.6,
  side_clearance = 0.10,
  depth_clearance = 0.10,
  footprint_wall = 2,
  vase_linewidth = 0.6,
  vase_overhang_angle = 45,
  head_cfg = ochead_cfg()
) =
  let (
    _head_cfg = struct_merge(ochead_cfg(), head_cfg),
    head_middle_height = struct_val(_head_cfg, "middle_height"),
    head_nub_to_top = struct_val(_head_cfg, "nub_to_top_distance"),
    head_large_rect_width = struct_val(_head_cfg, "large_rect_width"),
    head_large_rect_height = struct_val(_head_cfg, "large_rect_height"),
    head_large_rect_chamfer = struct_val(_head_cfg, "large_rect_chamfer"),
    head_small_rect_width = struct_val(_head_cfg, "small_rect_width"),
    head_small_rect_height = struct_val(_head_cfg, "small_rect_height"),
    head_small_rect_chamfer = struct_val(_head_cfg, "small_rect_chamfer"),
    head_back_pos_offset = struct_val(_head_cfg, "back_pos_offset"),
    bottom_height = struct_val(_head_cfg, "bottom_height") + ang_adj_to_opp(45 / 2, side_clearance) + depth_clearance,
    top_height = struct_val(_head_cfg, "top_height") - ang_adj_to_opp(45 / 2, side_clearance),
    total_height = top_height + head_middle_height + bottom_height,
    nub_to_top_distance = head_nub_to_top + side_clearance,
    small_rect_width = head_small_rect_width + side_clearance * 2,
    small_rect_height = head_small_rect_height + side_clearance * 2,
    small_rect_chamfer = head_small_rect_chamfer + side_clearance - ang_adj_to_opp(45 / 2, side_clearance),
    large_rect_width = head_large_rect_width + side_clearance * 2,
    large_rect_height = head_large_rect_height + side_clearance * 2,
    large_rect_chamfer = head_large_rect_chamfer + side_clearance - ang_adj_to_opp(45 / 2, side_clearance),
    middle_to_bottom = large_rect_height - large_rect_width / 2 - head_back_pos_offset,
    top_profile = back(
      small_rect_width / 2 + head_back_pos_offset,
      rect([small_rect_width, small_rect_height], chamfer=[small_rect_chamfer, small_rect_chamfer, 0, 0], anchor=BACK)
    ),
    bottom_profile = back(
      large_rect_width / 2 + head_back_pos_offset,
      rect([large_rect_width, large_rect_height], chamfer=[large_rect_chamfer, large_rect_chamfer, 0, 0], anchor=BACK)
    ),
    footprint = back(
      large_rect_width / 2 + head_back_pos_offset + footprint_wall,
      rect(
        [
          large_rect_width + footprint_wall * 2,
          large_rect_height + footprint_wall * 2,
        ],
        chamfer=[
          large_rect_chamfer + footprint_wall - ang_adj_to_opp(45 / 2, footprint_wall),
          large_rect_chamfer + footprint_wall - ang_adj_to_opp(45 / 2, footprint_wall),
          0,
          0,
        ],
        anchor=BACK
      )
    ),
    top_bridge_offset = (edge_feature == "Both" || edge_feature == "Top") ? max(0, edge_bridge_min_w - top_height) : 0,
    side_bridge_offset = (edge_feature == "Both" || edge_feature == "Side") ? max(0, edge_bridge_min_w - top_height) : 0,
    side_cliff_offset = (edge_feature == "Both" || edge_feature == "Side") ? max(0, edge_wall_min_w - top_height) : 0,
    bridge_offset_profile = right(side_bridge_offset / 2 - side_cliff_offset / 2, back(small_rect_width / 2 + head_back_pos_offset + top_bridge_offset, rect([small_rect_width + side_bridge_offset + side_cliff_offset, small_rect_height + OCSLOT_MOVE_DISTANCE + OCSLOT_ONRAMP_CLEARANCE + top_bridge_offset], chamfer=[small_rect_chamfer + top_bridge_offset + side_bridge_offset, small_rect_chamfer + top_bridge_offset + side_cliff_offset, 0, 0], anchor=BACK))),
    vase_wall_thickness = vase_linewidth * 2,
    vase_bottom_height = bottom_height + ang_adj_to_opp(45 / 2, vase_wall_thickness),
    vase_top_height = top_height - ang_adj_to_opp(45 / 2, vase_wall_thickness),
    vase_sweep_profile_base = [
      [0, 0],
      [0, vase_bottom_height],
      [min(head_middle_height, total_height - vase_bottom_height), total_height],
      [head_middle_height + vase_wall_thickness, total_height],
      [head_middle_height + vase_wall_thickness, bottom_height + head_middle_height],
      [vase_wall_thickness, bottom_height],
      [vase_wall_thickness, 0],
    ],
    vase_sweep_profile = total_height - vase_bottom_height > head_middle_height ? list_insert(vase_sweep_profile_base, 2, [head_middle_height, vase_bottom_height + head_middle_height]) : vase_sweep_profile_base
  ) struct_set(
    [], [
      "edge_feature",
      edge_feature,
      "edge_bridge_min_w",
      edge_bridge_min_w,
      "edge_wall_min_w",
      edge_wall_min_w,
      "side_clearance",
      side_clearance,
      "depth_clearance",
      depth_clearance,
      "footprint_wall",
      footprint_wall,
      "bottom_height",
      bottom_height,
      "top_height",
      top_height,
      "total_height",
      total_height,
      "nub_to_top_distance",
      nub_to_top_distance,
      "small_rect_width",
      small_rect_width,
      "small_rect_height",
      small_rect_height,
      "small_rect_chamfer",
      small_rect_chamfer,
      "large_rect_width",
      large_rect_width,
      "large_rect_height",
      large_rect_height,
      "large_rect_chamfer",
      large_rect_chamfer,
      "middle_to_bottom",
      middle_to_bottom,
      "top_profile",
      top_profile,
      "bottom_profile",
      bottom_profile,
      "footprint",
      footprint,
      "top_bridge_offset",
      top_bridge_offset,
      "side_bridge_offset",
      side_bridge_offset,
      "side_cliff_offset",
      side_cliff_offset,
      "bridge_offset_profile",
      bridge_offset_profile,
      "vase_linewidth",
      vase_linewidth,
      "vase_wall_thickness",
      vase_wall_thickness,
      "vase_bottom_height",
      vase_bottom_height,
      "vase_top_height",
      vase_top_height,
      "vase_sweep_profile",
      vase_sweep_profile,
      "vase_overhang_angle",
      vase_overhang_angle,
      "head_cfg",
      _head_cfg,
    ]
  );

function connector_slot_cfg(
  coin_slot_height = 2.6,
  coin_slot_width = 13,
  coin_slot_thickness = 2.4,
  flat_slot_height = 5,
  flat_slot_width = 6.5,
  flat_slot_height_offset = 0.7,
  flat_slot_start_thickness = 1.8,
  flat_slot_end_thickness = 1.2
) =
  let (
    coin_slot_radius = coin_slot_height / 2 + coin_slot_width ^ 2 / (8 * coin_slot_height)
  ) struct_set(
    [], [
      "coin_slot_height",
      coin_slot_height,
      "coin_slot_width",
      coin_slot_width,
      "coin_slot_thickness",
      coin_slot_thickness,
      "coin_slot_radius",
      coin_slot_radius,
      "flat_slot_height",
      flat_slot_height,
      "flat_slot_width",
      flat_slot_width,
      "flat_slot_height_offset",
      flat_slot_height_offset,
      "flat_slot_start_thickness",
      flat_slot_start_thickness,
      "flat_slot_end_thickness",
      flat_slot_end_thickness,
    ]
  );

module openconnect_head(head_type = "head", head_cfg = [], slot_cfg = [], add_nubs = "Both", nub_flattop = false, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  _head_cfg = struct_merge(ochead_cfg(), head_cfg);
  cfg = head_type == "head" ? _head_cfg : struct_merge(ocslot_cfg(head_cfg=_head_cfg), slot_cfg);

  _nub_depth = struct_val(_head_cfg, "nub_depth");
  _nub_tip_height = struct_val(_head_cfg, "nub_tip_height");
  _nub_fillet = struct_val(_head_cfg, "nub_fillet");
  _middle_height = struct_val(_head_cfg, "middle_height");
  _back_pos_offset = struct_val(_head_cfg, "back_pos_offset");

  bottom_profile = struct_val(cfg, "bottom_profile");
  top_profile = struct_val(cfg, "top_profile");
  bottom_height = struct_val(cfg, "bottom_height");
  top_height = struct_val(cfg, "top_height");
  large_rect_width = struct_val(cfg, "large_rect_width");
  large_rect_height = struct_val(cfg, "large_rect_height");
  nub_to_top_distance = struct_val(cfg, "nub_to_top_distance");

  total_height = bottom_height + top_height + _middle_height;

  // Slot heads may inset the right nub when the top bridge widens. ochead_cfg does not have this parameter.
  nub_inset_right = struct_val(cfg, "side_bridge_offset", 0);

  nub_angle_left = nub_taperin ? adj_opp_to_ang(_middle_height, _middle_height - _nub_depth) : 0;
  // bridging doesn't work well with tapered nub
  // nub_angle_right =
  //   nub_taperin && _middle_height - _nub_depth - nub_inset_right > 0 ? adj_opp_to_ang(_middle_height - nub_inset_right, _middle_height - _nub_depth - nub_inset_right)
  //   : 0;

  attachable(anchor, spin, orient, size=[large_rect_width, large_rect_width, total_height]) {
    tag_scope() down(total_height / 2) difference() {
          union() {
            linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
            up(bottom_height - EPS) hull() {
                up(_middle_height) linear_extrude(h=EPS) polygon(offset(top_profile, delta=size_offset));
                linear_extrude(h=EPS) polygon(offset(bottom_profile, delta=size_offset));
              }
            if (top_height + excess_thickness > 0)
              up(bottom_height + _middle_height - EPS)
                linear_extrude(h=top_height + excess_thickness + EPS) polygon(offset(top_profile, delta=size_offset));
          }
          back(large_rect_width / 2 - nub_to_top_distance + _back_pos_offset) {
            if (add_nubs == "Left" || add_nubs == "Both")
              left(large_rect_width / 2 + size_offset + EPS)
                openconnect_lock(bottom_height=bottom_height, middle_height=_middle_height, nub_depth=_nub_depth, nub_tip_height=_nub_tip_height, nub_fillet=_nub_fillet, nub_angle=nub_angle_left, nub_flattop=nub_flattop);
            if (add_nubs == "Right" || add_nubs == "Both")
              right(large_rect_width / 2 + size_offset + EPS)
                xflip() openconnect_lock(bottom_height=bottom_height, middle_height=_middle_height, nub_depth=_nub_depth, nub_tip_height=_nub_tip_height, nub_fillet=_nub_fillet, nub_angle=0, nub_flattop=nub_flattop);
          }
        }
    children();
  }
}
module openconnect_lock(bottom_height, middle_height, nub_depth = OCHEAD_NUB_DEPTH, nub_tip_height = OCHEAD_NUB_TIP_HEIGHT, nub_fillet = OCHEAD_NUB_FILLET, nub_angle = 0, nub_flattop = false) {
  right(nub_depth) zrot(-90) {
      linear_extrude(bottom_height)
        trapezoid(h=nub_depth, w2=nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[nub_fillet, nub_flattop ? 0 : nub_fillet, nub_flattop ? 0 : -nub_fillet, -nub_fillet], anchor=BACK, $fn=64);
      up(bottom_height)
        linear_extrude(v=[0, tan(nub_angle) * middle_height, middle_height])
          trapezoid(h=nub_depth, w2=nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[nub_fillet, nub_flattop ? 0 : nub_fillet, nub_flattop ? 0 : -nub_fillet, -nub_fillet], anchor=BACK, $fn=64);
    }
}
module openconnect_slot(slot_type = "slot", slot_cfg = [], add_nubs = "Left", slot_entryramp_flip = false, excess_thickness = EPS, anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = struct_merge(ocslot_cfg(), slot_cfg);

  ocslot_edge_wall_min_width = struct_val(cfg, "edge_wall_min_w");

  ocslot_bottom_height = struct_val(cfg, "bottom_height");
  ocslot_top_height = struct_val(cfg, "top_height");
  ocslot_total_height = struct_val(cfg, "total_height");
  ocslot_nub_to_top_distance = struct_val(cfg, "nub_to_top_distance");
  ocslot_small_rect_width = struct_val(cfg, "small_rect_width");
  ocslot_small_rect_height = struct_val(cfg, "small_rect_height");
  ocslot_small_rect_chamfer = struct_val(cfg, "small_rect_chamfer");
  ocslot_large_rect_width = struct_val(cfg, "large_rect_width");
  ocslot_large_rect_height = struct_val(cfg, "large_rect_height");
  ocslot_large_rect_chamfer = struct_val(cfg, "large_rect_chamfer");
  ocslot_middle_to_bottom = struct_val(cfg, "middle_to_bottom");

  ocslot_top_profile = struct_val(cfg, "top_profile");
  ocslot_bottom_profile = struct_val(cfg, "bottom_profile");
  ocslot_footprint_wall = struct_val(cfg, "footprint_wall");
  ocslot_footprint = struct_val(cfg, "footprint");

  attachable(anchor, spin, orient, size=[OG_TILE_SIZE, OG_TILE_SIZE, ocslot_total_height]) {
    tag_scope() down(ocslot_total_height / 2) if (slot_type == "slot")
        conditional_flip(axis="X", condition=slot_entryramp_flip) ocslot_body(excess_thickness);
      else if (slot_type == "vase")
        ocvase_body();
    children();
  }
  module ocvase_body(cfg = cfg) {
    ocvase_wall_thickness = struct_val(cfg, "vase_wall_thickness");
    ocvase_bottom_height = struct_val(cfg, "vase_bottom_height");
    ocvase_top_height = struct_val(cfg, "vase_top_height");
    ocvase_sweep_profile = struct_val(cfg, "vase_sweep_profile");
    ocvase_overhang_angle = struct_val(cfg, "vase_overhang_angle");
    straight_base_length = ocslot_large_rect_height - ocslot_large_rect_chamfer;
    straight_extra_length = tan(ocvase_overhang_angle) * ocslot_total_height;
    _slot_head_cfg = struct_val(cfg, "head_cfg", ochead_cfg());
    _middle_height = struct_val(_slot_head_cfg, "middle_height");
    nub_angle = adj_opp_to_ang(_middle_height, _middle_height - struct_val(_slot_head_cfg, "nub_depth"));
    sweep_corner_radius = ocvase_wall_thickness * sqrt(2);
    sweep_corner_offset = ang_adj_to_opp(45 / 2, sweep_corner_radius - ocvase_wall_thickness);
    vase_sweep_path = ["setdir", 90, "move", straight_extra_length + straight_base_length - sweep_corner_offset, "arcleft", sweep_corner_radius, 45, "move", ocslot_large_rect_chamfer * sqrt(2)];
    fwd(ocslot_middle_to_bottom + straight_extra_length)
      diff() {
        xflip_copy() right(ocvase_wall_thickness + ocslot_large_rect_width / 2) path_sweep(ocvase_sweep_profile, path=turtle(vase_sweep_path));
        if (add_nubs == "Left" || add_nubs == "Right" || add_nubs == "Both")
          conditional_flip(axis="X", copy=add_nubs == "Both", condition=add_nubs == "Right" || add_nubs == "Both")
            left(ocvase_wall_thickness + ocslot_large_rect_width / 2) back(ocslot_large_rect_height + straight_extra_length - ocslot_nub_to_top_distance) {
                _nub_depth = struct_val(_slot_head_cfg, "nub_depth");
                _nub_tip_h = struct_val(_slot_head_cfg, "nub_tip_height");
                _nub_fillet = struct_val(_slot_head_cfg, "nub_fillet");
                right(ocvase_wall_thickness)
                  openconnect_lock(bottom_height=ocslot_bottom_height, middle_height=_middle_height, nub_depth=_nub_depth, nub_tip_height=_nub_tip_h, nub_fillet=_nub_fillet, nub_angle=nub_angle);
                left(EPS)
                  tag("remove") openconnect_lock(bottom_height=ocvase_bottom_height, middle_height=_middle_height, nub_depth=_nub_depth, nub_tip_height=_nub_tip_h, nub_fillet=_nub_fillet, nub_angle=nub_angle);
              }
        xrot(90 - ocvase_overhang_angle) tag("remove") cuboid([OG_TILE_SIZE, 60, ocslot_total_height * 2], anchor=BOTTOM + FRONT);
      }
  }
  module ocslot_body(excess_thickness = 0) {
    _slot_head_cfg = struct_val(cfg, "head_cfg", ochead_cfg());
    _middle_height = struct_val(_slot_head_cfg, "middle_height");
    _back_pos_offset = struct_val(_slot_head_cfg, "back_pos_offset");
    _slot_move_distance = struct_val(_slot_head_cfg, "slot_move_distance", OCSLOT_MOVE_DISTANCE);
    _slot_onramp_clearance = struct_val(_slot_head_cfg, "slot_onramp_clearance", OCSLOT_ONRAMP_CLEARANCE);

    ocslot_bridge_offset_profile = struct_val(cfg, "bridge_offset_profile");
    ocslot_side_excess_profile = [
      [0, 0],
      [ocslot_large_rect_width / 2, 0],
      [ocslot_large_rect_width / 2, ocslot_bottom_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + _middle_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + _middle_height + ocslot_top_height + excess_thickness],
      [0, ocslot_bottom_height + _middle_height + ocslot_top_height + excess_thickness],
    ];
    difference() {
      union() {
        openconnect_head(head_type="slot", slot_cfg=cfg, add_nubs=add_nubs, excess_thickness=excess_thickness);
        back(_back_pos_offset) xrot(90) up(ocslot_middle_to_bottom) linear_extrude(_slot_move_distance + _slot_onramp_clearance + _back_pos_offset) xflip_copy() polygon(ocslot_side_excess_profile);
        up(ocslot_bottom_height) linear_extrude(ocslot_top_height + _middle_height + EPS) polygon(ocslot_bridge_offset_profile);
        fwd(_slot_move_distance) {
          linear_extrude(ocslot_bottom_height) onramp_2d();
          up(ocslot_bottom_height)
            linear_extrude(_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
          left(_middle_height) up(ocslot_bottom_height + _middle_height)
              linear_extrude(ocslot_top_height + excess_thickness) onramp_2d();
        }
        if (excess_thickness > 0)
          fwd(ocslot_small_rect_chamfer) cuboid([ocslot_small_rect_width, ocslot_small_rect_height, ocslot_total_height + excess_thickness], anchor=BOTTOM);
      }
      fwd(OG_TILE_SIZE / 2)
        cuboid([OG_TILE_SIZE, ocslot_edge_wall_min_width, ocslot_bottom_height + _middle_height + ocslot_top_height + excess_thickness + EPS], anchor=FRONT + BOTTOM);
    }
  }
  module onramp_2d() {
    _slot_head_cfg = struct_val(cfg, "head_cfg", ochead_cfg());
    _middle_height = struct_val(_slot_head_cfg, "middle_height");
    _back_pos_offset = struct_val(_slot_head_cfg, "back_pos_offset");
    _slot_onramp_clearance = struct_val(_slot_head_cfg, "slot_onramp_clearance", OCSLOT_ONRAMP_CLEARANCE);
    offset(delta=_slot_onramp_clearance)
      left(_slot_onramp_clearance + _middle_height) back(ocslot_large_rect_width / 2 + _back_pos_offset) {
          rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
          trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
        }
  }
}

function _openconnect_slot_footprint_rotate(slot_slide_direction) =
  slot_slide_direction == "Left" ? 90
  : slot_slide_direction == "Right" ? -90
  : slot_slide_direction == "Down" ? 180
  : 0;

module openconnect_slot_grid_limit_debug(slot_cfg = [], horizontal_grids = 1, vertical_grids = 1, slot_slide_direction = "Up", excess_thickness = EPS, limit_region = [], anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = struct_merge(ocslot_cfg(), slot_cfg);
  ocslot_total_height = struct_val(cfg, "total_height");
  ocslot_footprint = struct_val(cfg, "footprint");
  has_limit_region = is_region(limit_region);
  footprint_rotate = _openconnect_slot_footprint_rotate(slot_slide_direction);
  debug_z = ocslot_total_height / 2 + excess_thickness + EPS;
  debug_h = 0.04;
  attachable(anchor, spin, orient, size=[horizontal_grids * OG_TILE_SIZE, vertical_grids * OG_TILE_SIZE, ocslot_total_height]) {
    tag_scope() {
      if (has_limit_region)
        %color("blue", 0.18)
          up(debug_z)
            linear_extrude(height=debug_h)
              region(limit_region);
      for (i = [0:horizontal_grids - 1])
        for (j = [0:vertical_grids - 1]) {
          x_offset = -(horizontal_grids - i * 2 - 1) * OG_TILE_SIZE / 2;
          y_offset = (vertical_grids - j * 2 - 1) * OG_TILE_SIZE / 2;
          checked_footprint = zrot(footprint_rotate, ocslot_footprint);
          footprint_in_region = !has_limit_region || is_pos_shape_in_region(cp=[x_offset, y_offset], footprint=checked_footprint, limit_region=limit_region);
          footprint_path = [for (pt = checked_footprint) [x_offset, y_offset] + pt];
          %color(has_limit_region ? (footprint_in_region ? "green" : "red") : "orange", 0.28)
            up(debug_z + debug_h)
              linear_extrude(height=debug_h)
                polygon(footprint_path);
        }
    }
    children();
  }
}

module openconnect_slot_grid(slot_cfg = [], slot_type = "slot", horizontal_grids = 1, vertical_grids = 1, slot_slide_direction = "Up", slot_position = "All", slot_lock_distribution = "None", slot_lock_side = "Left", slot_entryramp_flip = false, excess_thickness = EPS, except_slot_pos = [], chamfer = 0, rounding = 0, limit_region = [], anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = struct_merge(ocslot_cfg(), slot_cfg);
  // Slot dimensions needed for grid sizing/placement
  ocslot_total_height = struct_val(cfg, "total_height");
  ocslot_footprint = struct_val(cfg, "footprint");
  has_limit_region = is_region(limit_region);
  attachable(anchor, spin, orient, size=[horizontal_grids * OG_TILE_SIZE, vertical_grids * OG_TILE_SIZE, ocslot_total_height]) {
    grid_slot_spin = slot_slide_direction == "Left" ? -90 : slot_slide_direction == "Right" ? 90 : slot_slide_direction == "Down" ? 180 : 0;
    grid_slot_flip = slot_slide_direction == "Right" || slot_slide_direction == "Down" ? !slot_entryramp_flip : slot_entryramp_flip;
    footprint_rotate = _openconnect_slot_footprint_rotate(slot_slide_direction);
    tag_scope() down(ocslot_total_height / 2) intersect() {
          cuboid([horizontal_grids * OG_TILE_SIZE, vertical_grids * OG_TILE_SIZE, ocslot_total_height + excess_thickness], edges="Z", chamfer=chamfer, rounding=rounding, anchor=BOTTOM) {
            for (i = [0:horizontal_grids - 1])
              for (j = [0:vertical_grids - 1]) {
                x_offset = -(horizontal_grids - i * 2 - 1) * OG_TILE_SIZE / 2;
                y_offset = (vertical_grids - j * 2 - 1) * OG_TILE_SIZE / 2;
                checked_footprint = zrot(footprint_rotate, ocslot_footprint);
                if (!has_limit_region || is_pos_shape_in_region(cp=[x_offset, y_offset], footprint=checked_footprint, limit_region=limit_region))
                  if (is_grid_pos_described(i, j, horizontal_grids, vertical_grids, slot_position, except_slot_pos))
                    right(x_offset) back(y_offset)
                        attach(BOTTOM, BOTTOM, inside=true, spin=grid_slot_spin)
                          tag("intersect") openconnect_slot(slot_type=slot_type, slot_cfg=slot_cfg, add_nubs=is_grid_pos_described(i, j, horizontal_grids, vertical_grids, slot_lock_distribution) ? slot_lock_side : "", slot_entryramp_flip=grid_slot_flip, excess_thickness=excess_thickness);
              }
          }
        }
    children();
  }
}
//END openConnect slot modules

//BEGIN openConnect connectors
module openconnect_screw(threads_height = OG_STANDARD_THICKNESS, text_cfg = [], head_cfg = [], connectorslot_cfg = [], threads_cfg = [], folded = false) {
  _head_cfg = struct_merge(ochead_cfg(), head_cfg);
  _total_height = struct_val(_head_cfg, "total_height");
  _middle_to_bot = struct_val(_head_cfg, "middle_to_bottom");
  _slot_cfg = struct_merge(connector_slot_cfg(), connectorslot_cfg);

  ocfold_gap_width = 0.4;
  ocfold_gap_height = 0.2;
  ocscrew_overhang_cyl_diameter = 15.6;

  ocscrew_coin_slot_height = struct_val(_slot_cfg, "coin_slot_height");
  ocscrew_coin_slot_width = struct_val(_slot_cfg, "coin_slot_width");
  ocscrew_coin_slot_thickness = struct_val(_slot_cfg, "coin_slot_thickness");
  ocscrew_coin_slot_radius = struct_val(_slot_cfg, "coin_slot_radius");
  ocscrew_flat_slot_height = struct_val(_slot_cfg, "flat_slot_height");
  ocscrew_flat_slot_width = struct_val(_slot_cfg, "flat_slot_width");
  ocscrew_flat_slot_height_offset = struct_val(_slot_cfg, "flat_slot_height_offset");
  ocscrew_flat_slot_start_thickness = struct_val(_slot_cfg, "flat_slot_start_thickness");
  ocscrew_flat_slot_end_thickness = struct_val(_slot_cfg, "flat_slot_end_thickness");

  _screw_threads_cfg = struct_set(threads_cfg, ["threads_clearance", 0]);
  _shifted_offsets = [for (p = struct_val(text_cfg, "pos_offsets", [])) [p[0], p[1] + (folded ? 2 : 0)]];
  _text_cfg_shifted = struct_set(text_cfg, ["pos_offsets", _shifted_offsets]);

  tag_scope() conditional_fold(
      body_thickness=threads_height + _total_height,
      fold_position=_middle_to_bot + EPS,
      fold_gap_width=ocfold_gap_width, fold_gap_height=ocfold_gap_height,
      fold_sliceoff=ocfold_gap_width / 2, condition=folded
    )
      up(threads_height + _total_height) xrot(180) zrot(180)
            diff() {
              up(_total_height - EPS)
                snap_threads(threads_height=threads_height, threads_cfg=_screw_threads_cfg, text_cfg=_text_cfg_shifted);
              tag_intersect("") {
                tag(folded ? "keep" : "") openconnect_head(head_type="head", add_nubs="Both", head_cfg=_head_cfg);
                if (!folded)
                  tag("intersect") up(_total_height - EPS) right(0.32) back(0.45)
                          cyl(d2=ocscrew_overhang_cyl_diameter, d1=ocscrew_overhang_cyl_diameter + _total_height * 2, h=_total_height, anchor=TOP);
              }
              tag("remove") up(ocscrew_coin_slot_height) zrot(90) xrot(90)
                      cyl(r=ocscrew_coin_slot_radius, h=ocscrew_coin_slot_thickness, $fn=128, anchor=BACK) {
                        fwd(ocscrew_flat_slot_height_offset)
                          attach(BACK, BOTTOM)
                            prismoid(
                              size1=[ocscrew_flat_slot_width, ocscrew_flat_slot_start_thickness],
                              size2=[undef, ocscrew_flat_slot_end_thickness],
                              h=ocscrew_flat_slot_height - ocscrew_coin_slot_height + ocscrew_flat_slot_height_offset,
                              xang=[90, 90]
                            );
                        left(ocscrew_coin_slot_width / 2)
                          attach(BACK, BACK, inside=true)
                            cuboid([ocscrew_coin_slot_width, ocscrew_coin_slot_radius, ocscrew_coin_slot_thickness]);
                      }
            }
}

// ===================== multiconnectSlotDesign.scad =====================
/*
 * multiconnectSlotDesign.scad
 * Adapted from cschneid/MultiConnectOpenSCAD (CC-BY-NC, Chris Schneider).
 * Changes vs. original:
 *   - Top-level demo call removed (was: multiconnectBack(...) at file scope) so
 *     this file is safe for both `use` and `include` without rendering stray geometry.
 *   - Slot customisation options (formerly file-level globals: slotQuickRelease,
 *     dimpleScale, slotTolerance, slotDepthMicroadjustment, onRampEnabled,
 *     onRampEveryXSlots) are now explicit parameters of multiconnectBack() and the
 *     inner slotTool() so the module is fully self-contained under `use`.
 *
 * Original file header:
 * This file is the master copy of the multiconnect slot back.
 * All components of this file are required in any file using this backer.
 */

//BEGIN MODULES
//Slotted back Module
// backWidth, backHeight: outer dimensions of the backer plate (mm).
// distanceBetweenSlots: slot pitch (25mm = standard MultiBoard).
// dimples:   true  → include locking dimple in slot (default); false = quick-release.
// onRamp:    true  → add on-ramp cylinders for easy mounting of tall items.
// slotTolerance:           scale factor for slot profile (default 1.00).
// dimpleScale:             scale factor for the dimple geometry (default 1).
// slotDepthMicroadjustment: moves slot in (+) or out (-) in mm (default 0).
// onRampEveryXSlots:       on-ramp frequency; 1 = every slot (default 1).
module multiconnectBack(backWidth, backHeight, distanceBetweenSlots,
                        dimples=true, onRamp=true,
                        slotTolerance=1.00, dimpleScale=1,
                        slotDepthMicroadjustment=0, onRampEveryXSlots=1)
{
    // Derive the legacy boolean names used in slot geometry.
    _slotQuickRelease = !dimples;
    _onRampEnabled    = onRamp;

    //slot count calculates how many slots can fit on the back. Based on internal width for buffer.
    //slot width needs to be at least the distance between slot for at least 1 slot to generate
    let (backWidth  = max(backWidth,  distanceBetweenSlots),
         backHeight = max(backHeight, 25),
         slotCount  = floor(backWidth / distanceBetweenSlots),
         backThickness = 6.5)
    {
        difference() {
            translate(v = [0, -backThickness, 0]) cube(size = [backWidth, backThickness, backHeight]);
            //Loop through slots and center on the item
            //Note: I kept doing math until it looked right. It's possible this can be simplified.
            for (slotNum = [0:1:slotCount-1]) {
                translate(v = [
                    distanceBetweenSlots/2 + (backWidth/distanceBetweenSlots - slotCount)*distanceBetweenSlots/2 + slotNum*distanceBetweenSlots,
                    -2.35 + slotDepthMicroadjustment,
                    backHeight - 13
                ]) {
                    color(c = "red")
                    slotTool(backHeight,
                             _slotQuickRelease, _onRampEnabled,
                             slotTolerance, dimpleScale,
                             slotDepthMicroadjustment, onRampEveryXSlots,
                             distanceBetweenSlots);
                }
            }
        }
    }

    //Create Slot Tool
    module slotTool(totalHeight,
                    _slotQuickRelease, _onRampEnabled,
                    slotTolerance, dimpleScale,
                    slotDepthMicroadjustment, onRampEveryXSlots,
                    distanceBetweenSlots)
    {
        scale(v = slotTolerance)
        //slot minus optional dimple with optional on-ramp
        let (slotProfile = [[0,0],[10.15,0],[10.15,1.2121],[7.65,3.712],[7.65,5],[0,5]])
        difference() {
            union() {
                //round top
                rotate(a = [90,0,0,])
                    rotate_extrude($fn=50)
                        polygon(points = slotProfile);
                //long slot
                translate(v = [0,0,0])
                    rotate(a = [180,0,0])
                    linear_extrude(height = totalHeight+1)
                        union(){
                            polygon(points = slotProfile);
                            mirror([1,0,0])
                                polygon(points = slotProfile);
                        }
                //on-ramp
                if(_onRampEnabled)
                    for(y = [1:onRampEveryXSlots:totalHeight/distanceBetweenSlots])
                        translate(v = [0,-5,-y*distanceBetweenSlots])
                            rotate(a = [-90,0,0])
                                color(c = "orange") cylinder(h = 5, r1 = 12, r2 = 10.15);
            }
            //dimple
            if (_slotQuickRelease == false)
                scale(v = dimpleScale)
                rotate(a = [90,0,0,])
                    rotate_extrude($fn=50)
                        polygon(points = [[0,0],[0,1.5],[1.5,0]]);
        }
    }
}

// ===================== derived values + geometry (main) =====================
/* [Hidden] */
Preview_Warnings = true;   // render an in-preview label if the bore is clamped (tests set false)
_footprint = mount_face_clear_xy(Mount_System, MB_Slots, 1);
_preset    = Thread_Preset == "Custom" ? "Custom" : Thread_Preset;
_major     = Thread_Preset == "Custom" ? Thread_Major_Diameter : 0;
_pitch     = Thread_Preset == "Custom" ? Thread_Pitch : preset_pitch(_preset);
_profile   = Thread_Preset == "Custom" ? Thread_Profile : "Trapezoidal";
_bore_req  = Cable_Bore_Diameter;
_bore      = clamped_bore(_bore_req, _footprint, _pitch, Thread_Clearance, _major);
_nut_h     = max(Nut_Height, 3 * _pitch);
// barrel taller than the ring (so it can travel down) AND tall enough that the cable channel
// fits above the modest floor
_socket_h  = max(_nut_h + 6, 14, _bore + barrel_base() + 2);

assert(part_od(_bore, _pitch, Thread_Clearance, _major) <= _footprint + 0.001,
       "clamp (ring/flare) exceeds mount footprint after clamping");
if (Nut_Height < 3*_pitch)
    echo(str("NOTE: Nut_Height raised from ", Nut_Height, " to ", _nut_h,
             " mm for >=3 thread turns at pitch ", _pitch, "."));
if (_bore < _bore_req)
    echo(str("NOTE: Cable_Bore_Diameter clamped from ", _bore_req, " to ", _bore,
             " mm to fit the ", Mount_System, " footprint (", _footprint, " mm)."));

module _body()
    clamp_body(mount_system=Mount_System, board_type=Board_Type, snap_shape=Snap_Shape,
               oc_slots=1, oc_lock=OC_Lock,
               mb_slots=MB_Slots, mb_dimples=MB_Dimples, mb_onramp=MB_OnRamp,
               bore=_bore, preset=_preset, socket_height=_socket_h,
               clearance=Thread_Clearance, major_override=_major, profile=_profile);

module _nut()
    ring_nut(bore=_bore, preset=_preset, height=_nut_h,
             clearance=Thread_Clearance, major_override=_major, grip=Nut_Grip, profile=_profile);

// Visible warning in the MakerWorld 3D preview when the requested bore was clamped to fit the cell.
// (echo() isn't surfaced to MakerWorld users, so we float a red label above the part instead.)
module _bore_warning()
    color([1, 0, 0])
        translate([0, 0, _socket_h + 6])
            linear_extrude(1)
                text(str("BORE CLAMPED TO ", _bore, "mm - exceeds ", Mount_System, " cell"),
                     size=3, halign="center", valign="center");

if (Part == "Body") _body();
else if (Part == "Ring Nut") _nut();
else { _body(); right(_footprint + 8) _nut(); }
if (_bore < _bore_req && Preview_Warnings) _bore_warning();
