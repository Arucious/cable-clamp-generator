use <params.scad>
include <BOSL2/std.scad>
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

// Threaded socket: cylinder with an INTERNAL thread, open along Y for the cable. Base at z=0.
module threaded_socket(bore, preset, height, clearance=0.4, major_override=0, profile="Trapezoidal") {
    p     = preset_pitch(preset);
    major = thread_major(bore, p, major_override);
    od    = socket_od(bore, p, major_override);
    difference() {
        cylinder(h=height, d=od);
        up(-0.5) _thread_rod(d=major, l=height+1, pitch=p, profile=profile, internal=true, slop=clearance);
        up(-0.5) cuboid([bore, od+2, bore], anchor=BOTTOM);   // open Y cable channel
    }
}

// Externally-threaded plug: a threaded INSERTION zone (engages the socket) topped by a
// full-height GRIP BODY — the entire exposed cylinder is the grip (knurled/flats/wings).
// `height` is the threaded insertion length; the grip body is the graspable part above it.
module nut_plug(bore, preset, height, clearance=0.4, major_override=0, grip="Flats", profile="Trapezoidal") {
    p          = preset_pitch(preset);
    major      = thread_major(bore, p, major_override);
    od         = socket_od(bore, p, major_override);
    grip_h     = max(height, 10);   // exposed grip body — the dominant, graspable part
    grip_d     = od + 2;            // overhangs the socket rim (acts as a stop + leverage)
    union() {
        _thread_rod(d=major - 2*clearance, l=height, pitch=p, profile=profile, internal=false);
        up(height - 0.01) _grip(grip, d=grip_d, h=grip_h + 0.01);   // small overlap, no seam
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
