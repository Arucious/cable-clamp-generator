// Pure functions: thread-preset resolution and derived dimensions. No customizer vars here.
OG_SNAP_WIDTH = 24.8;   // openGrid snap footprint (also footprint ceiling for the socket)
MIN_WALL      = 0.8;    // OG_MIN_WALL_WIDTH

function preset_pitch(preset) =
    preset == "Fine"   ? 2 :
    preset == "Coarse" ? 4 :
    /* openGrid standard / Custom default */ 3;

function thread_depth(pitch) = 0.6 * pitch;

function thread_major(bore, pitch, major_override=0) =
    major_override > 0 ? major_override : bore + 2 * thread_depth(pitch);

function socket_od(bore, pitch, major_override=0) =
    thread_major(bore, pitch, major_override) + 2 * MIN_WALL;

function clamped_bore(bore, footprint, pitch, major_override=0) =
    let (od = socket_od(bore, pitch, major_override))
    od <= footprint ? bore : footprint - 2*MIN_WALL - 2*thread_depth(pitch);
