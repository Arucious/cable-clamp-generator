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

use <clamp.scad>
use <params.scad>
use <mount.scad>
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
