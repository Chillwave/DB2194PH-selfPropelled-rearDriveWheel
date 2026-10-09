// ============================================================
//  Axle spacer for the PowerSmart printed drive wheel
//  Stack: housing -> spacer -> bearing tube -> nylock
//  11 mm = stud smooth section 40 minus bearing tube 29
//  OD stays under 19 so it only touches the bearing INNER race.
//  Print 100 percent infill, it is clamped hardware.
// ============================================================

thickness = 11;     // stud smooth length minus bearing tube length
stud_d    = 13.6;   // clearance over the 13 mm stud
od        = 18.5;   // inner race contact only, under 19

$fn = 120;
difference() {
    cylinder(h = thickness, d = od);
    translate([0,0,-0.01]) cylinder(h = thickness + 0.02, d = stud_d);
}
