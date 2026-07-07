// ============================================================
//  PowerSmart DB2194PH drive wheel  ::  v6.1  SUPPORT-FREE, pinion-safe ribs
//
//  PRINT ORIENTATION: as modeled. z=0 is the OUTBOARD face,
//  flat on the bed. Everything grows straight up:
//    * gear teeth are FULL HEIGHT vertical walls (no supports,
//      stronger, pinion meshes the top section near the mower)
//    * flat base disc = first layers, all structure lands on it
//    * bearing pocket opens from the TOP, its only overhang is
//      a 45 degree chamfer where the nut recess necks down
//    * nut recess is a straight vertical hole to the bed
//  Zero supports. Zero bridges. One flat face.
//
//  CONFIRMED SPECS (test ring meshed + rolled on the mower):
//    module 2.5, ring 52T internal, pinion 14T steel
//    ring outer 136.2, center distance 47.5
//    bearing 30 OD x ~12, axle stud ~13, wheel 203 x 50
// ============================================================

part = "wheel";            // "wheel" | "tire"
show_pinion = false;       // preview overlay only

/* ---- envelope ---- */
wheel_od    = 203.2;
wheel_width = 50;          // set 26 for a skinny test version
rim_id      = 184;

/* ---- gear (locked) ---- */
gear_module    = 2.5;
gear_teeth     = 52;
pinion_teeth   = 14;
pressure_angle = 20;
gear_backlash  = 0.40;

/* ---- base / structure ---- */
base_thick   = 5;          // flat outboard disc on the bed
n_ribs       = 6;          // ribs OUTSIDE the gear, gear wall -> rim
rib_w        = 10;
n_inner_ribs = 6;          // gusset ribs hub -> gear wall
pinion_reach = 18;         // how deep the pinion engages from the top
                           // face. MEASURE: pinion face width + standoff.
rib_clear    = 2;          // margin under the pinion
lighten_d    = 26;         // through holes in the base (vertical = fine)

/* ---- hub / bearing ---- */
hub_od        = 46;
hub_h         = 30;        // hub top; bearing drops in from above
bearing_od    = 30.2;      // 30 bearing + press clearance
bearing_width = 12;
nut_recess_d  = 26;        // straight hole to the bed, socket access
shaft_d       = 13.5;      // not used for bore (nut recess covers it)

/* ---- tread ---- */
tread_style = "knurl";     // "knurl" | "slick"
knurl_count = 44; knurl_depth = 1.4; knurl_angle = 30;

$fn = 170; eps = 0.02;

/* ---- derived ---- */
pitch_r  = gear_module*gear_teeth/2;      // 65
tip_r    = pitch_r - gear_module;         // 62.5
root_r   = pitch_r + 1.25*gear_module;    // 68.125
gear_or  = root_r + 2.5;                  // outer wall of gear ring
pin_cd   = (gear_teeth-pinion_teeth)*gear_module/2;  // 47.5
tread_ir = rim_id/2;
bear_z0  = hub_h - bearing_width;         // bearing seat height

// sanity: pinion inner sweep vs hub
pin_inner_reach = pin_cd - (pinion_teeth/2+1)*gear_module; // ~27.5
assert(hub_od/2 + 2 < pin_inner_reach, "hub too fat for pinion sweep");

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

module pinion_2d() {
    pr=pinion_teeth*gear_module/2; pt=pr+gear_module; prt=pr-1.25*gear_module;
    cp=PI*gear_module; tt=cp/2-gear_backlash; a=(tt/pr)*90/PI;
    union(){ circle(r=prt);
        for(i=[0:pinion_teeth-1]){ ang=i*360/pinion_teeth;
            polygon([[prt*cos(ang-a*1.4),prt*sin(ang-a*1.4)],
                     [pt*cos(ang-a*0.6),pt*sin(ang-a*0.6)],
                     [pt*cos(ang+a*0.6),pt*sin(ang+a*0.6)],
                     [prt*cos(ang+a*1.4),prt*sin(ang+a*1.4)]]); } }
}

module tread_cuts() {
    if (tread_style=="knurl")
        for(dir=[1,-1]) for(i=[0:knurl_count-1])
            rotate([0,0,i*360/knurl_count])
                linear_extrude(height=wheel_width, twist=dir*knurl_angle, slices=20)
                    translate([wheel_od/2-knurl_depth/2,0])
                        square([knurl_depth*2,1.6],center=true);
}

module wheel_body() {
    difference() {
        union() {
            // 1. flat base disc, bed layer, full footprint
            cylinder(h=base_thick, d=wheel_od);
            // 2. rim + tread band, vertical
            difference(){
                cylinder(h=wheel_width, d=wheel_od);
                translate([0,0,-eps]) cylinder(h=wheel_width+2*eps, r=tread_ir);
            }
            // 3. FULL-HEIGHT ring gear, vertical teeth, lands on base
            translate([0,0,base_thick-eps])
                linear_extrude(height=wheel_width-base_thick+eps)
                    ring_gear_2d();
            // 4. hub boss
            cylinder(h=hub_h, d=hub_od);
            // 5. inner ribs: tall 45deg gusset at the hub (pinion
            //    cannot reach inside r ~27), then a LOW rail out to
            //    the gear wall, always below the pinion sweep.
            for(i=[0:n_inner_ribs-1]) rotate([0,0,i*360/n_inner_ribs])
                inner_gusset_rib();
            // 6. outer ribs gear wall -> rim, full height
            for(i=[0:n_ribs-1]) rotate([0,0,(i+0.5)*360/n_ribs])
                translate([gear_or-1,-rib_w/2,base_thick-eps])
                    cube([tread_ir-gear_or+2, rib_w, wheel_width-base_thick]);
        }
        // bearing pocket, opens from the TOP of the hub
        translate([0,0,bear_z0]) cylinder(h=bearing_width+eps, d=bearing_od);
        // 45 deg chamfer transition down to the nut recess (no bridge)
        translate([0,0,bear_z0-(bearing_od-nut_recess_d)/2-eps])
            cylinder(h=(bearing_od-nut_recess_d)/2+0.15,
                     d1=nut_recess_d, d2=bearing_od+0.01);
        // nut recess: straight vertical hole to the bed
        translate([0,0,-eps]) cylinder(h=bear_z0+eps, d=nut_recess_d);
        // lightening holes, vertical through the base between gear and rim? 
        // base extends under the gear zone: put holes inside gear circle,
        // between hub and gear, and they are plain vertical holes
        for(i=[0:5]) rotate([0,0,i*60+30])
            translate([(hub_od/2+tip_r)/2,0,-eps])
                cylinder(h=base_thick+2*eps, d=lighten_d);
        // tread
        tread_cuts();
    }
}

module inner_gusset_rib() {
    r0 = hub_od/2 - 2;                       // start inside hub
    r1 = tip_r - 1;                          // end at gear wall
    safe_r = pin_inner_reach - 1.5;          // pinion sweep boundary
    rail_h = max(2, min(6, wheel_width - pinion_reach - rib_clear - base_thick));
    g_top  = min(hub_h - base_thick, rail_h + (safe_r - r0));  // 45 deg
    xk     = r0 + (g_top - rail_h);          // knee of the chamfer
    translate([0, rib_w/2, base_thick-eps]) rotate([90,0,0])
        linear_extrude(height=rib_w)
            polygon([[r0,0],[r1,0],[r1,rail_h],[xk,rail_h],[r0,g_top]]);
}

module tpu_tire() {
    difference(){
        cylinder(h=wheel_width, d=wheel_od+8);
        translate([0,0,-eps]) cylinder(h=wheel_width+2*eps, d=wheel_od-0.6);
    }
}

if (part=="wheel") {
    wheel_body();
    if (show_pinion)
        color("red") translate([pin_cd,0,wheel_width-16])
            linear_extrude(height=18) pinion_2d();
}
if (part=="tire") tpu_tire();
