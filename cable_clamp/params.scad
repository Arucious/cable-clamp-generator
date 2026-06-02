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
