// ============================================================
//  Gear mesh test ring for the PowerSmart printed drive wheel
//  Same 52T module 2.5 ring gear as drive_wheel_v8.scad, 7 mm
//  thick on 3 spokes. About 10 to 15 g. Slide it on the stud
//  (bore rides the 13 mm stud, no bearing needed) and hand
//  check the mesh against the pinion before printing the wheel.
// ============================================================

gear_module    = 2.5;
gear_teeth     = 52;
pressure_angle = 20;
gear_backlash  = 0.40;
thick          = 7;
bore_d         = 13.5;
hub_d          = 24;
spoke_w        = 6;

$fn = 170; eps = 0.02;

pitch_r = gear_module*gear_teeth/2;
tip_r   = pitch_r - gear_module;
root_r  = pitch_r + 1.25*gear_module;
gear_or = root_r + 2.5;

module ring_gear_2d() {
    cp=PI*gear_module; t_pitch=cp/2-gear_backlash;
    lean=tan(pressure_angle);
    t_tip=max(t_pitch-2*(pitch_r-tip_r)*lean,0.8);
    t_root=t_pitch+2*(root_r-pitch_r)*lean;
    a_tip=(t_tip/tip_r)*90/PI; a_root=(t_root/root_r)*90/PI;
    difference(){ circle(r=gear_or); circle(r=root_r); }
    for(i=[0:gear_teeth-1]){ a=i*360/gear_teeth;
        polygon([
            [(root_r+eps)*cos(a-a_root),(root_r+eps)*sin(a-a_root)],
            [ tip_r*cos(a-a_tip), tip_r*sin(a-a_tip)],
            [ tip_r*cos(a+a_tip), tip_r*sin(a+a_tip)],
            [(root_r+eps)*cos(a+a_root),(root_r+eps)*sin(a+a_root)]]); }
}

linear_extrude(height=thick) difference() {
    union() {
        ring_gear_2d();
        circle(d=hub_d);
        for(i=[0:2]) rotate(i*120)
            translate([0,-spoke_w/2]) square([root_r, spoke_w]);
    }
    circle(d=bore_d);
}
