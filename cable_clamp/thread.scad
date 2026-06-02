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

// Body BARREL: an EXTERNALLY-threaded post, split by the cable channel into fingers. Base at z=0.
// The ring nut screws down around this and compresses the fingers onto the cable.
module threaded_socket(bore, preset, height, clearance=0.4, major_override=0, profile="Trapezoidal") {
    p     = preset_pitch(preset);
    major = thread_major(bore, p, major_override);   // external thread crest OD
    difference() {
        _thread_rod(d=major, l=height, pitch=p, profile=profile, internal=false);
        // cable channel along Y; starts above a thin base web so the fingers stay joined as a
        // collet (and the cable rests just above the mount), and runs out the top.
        up(0.8) cuboid([bore, major+2, height], anchor=BOTTOM);
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
