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

// Externally-threaded plug that screws into the socket and presses the bundle.
module nut_plug(bore, preset, height, clearance=0.4, major_override=0, grip="Flats", profile="Trapezoidal") {
    p     = preset_pitch(preset);
    major = thread_major(bore, p, major_override);
    union() {
        _thread_rod(d=major - 2*clearance, l=height, pitch=p, profile=profile, internal=false);
        up(height) _grip(grip, d=major, h=3);
    }
}

module _grip(grip, d, h) {
    if (grip == "Knurl")      cyl(d=d+1, h=h, chamfer=0.5, anchor=BOTTOM);
    else if (grip == "Wings") { cuboid([d*1.6, d*0.28, h], rounding=0.6, edges="Z", anchor=BOTTOM); cuboid([d*0.28, d*1.6, h], rounding=0.6, edges="Z", anchor=BOTTOM); }
    else /* Flats */          prismoid(size1=[d,d], size2=[d-1.5,d-1.5], h=h, anchor=BOTTOM);
}
