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
