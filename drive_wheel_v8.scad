// ============================================================
//  PowerSmart DB2194PH drive wheel  ::  v8  thermal press-fit pocket with crush ribs
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
//    bearing 13 bore x 30 body x 12 wide, 32 flange, 29 with tube
//    stud 13 smooth for 40, then 8 mm threads. wheel 203 x 50
// ============================================================

part = "wheel";            // "wheel" | "tire"
brim = true;               // fat built-in brim ring, snaps off after the
                           // print. PETG curls at the rim and wrecks the
                           // gear dimensions without it.
brim_w    = 7;             // ring width. 7 keeps a 203 wheel on a 220 bed
brim_h    = 1.0;           // 5 layers at 0.2, fights the curl pull
brim_bite = 0.25;          // XY fuse into the wheel edge, snap line
show_pinion = false;       // preview overlay only

/* ---- envelope ---- */
wheel_od    = 203.2;
wheel_width = 50;
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
pinion_reach = 24;         // how deep the pinion engages from the top
                           // face. MEASURE: pinion face width + standoff.
rib_clear    = 2;          // margin under the pinion
lighten_d    = 26;         // through holes in the base (vertical = fine)

/* ---- hub / bearing (ALL MEASURED off the real hardware) ---- */
hub_od        = 46;
hub_h         = wheel_width; // hub runs full height, flange seats at top
bearing_od    = 30.15;     // near-slip bore; the crush ribs do the gripping
crush_ribs    = 6;         // ridges inside the pocket that bite the bearing
rib_bite      = 0.30;      // how far each rib stands proud into the bore
rib_wide      = 1.4;       //
// INSTALL: heat the hub 70 to 80 C with a hair dryer (hot to touch,
// not glossy), optionally freeze the bearing, press flange-flush.
// Cooling shrink plus the ribs lock it. No glue needed.
bearing_width = 12;        // flanged body only (measured)
flange_od     = 32;        // measured
flange_clear  = 0.6;       // drop-in clearance on the flange
tube_len      = 29;        // bearing total incl extended inner race
stud_smooth   = 40;        // housing face to thread step (measured)
mount_gap     = 1.5;       // wheel face to housing running gap
nut_recess_d  = 26;        // straight hole to the bed, socket access
shaft_d       = 13.5;      // stud clearance

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
// flange seat plane, print coords (z0 = outboard face):
// stud smooth 40 minus tube 29 = tube inboard end 11 mm off the housing.
// wheel face sits mount_gap off the housing, so the flange plane lands
// (11 - mount_gap) into the wheel from its inboard face.
flange_seat_z = wheel_width - (stud_smooth - tube_len - mount_gap);  // 40.5
bear_z0  = flange_seat_z - bearing_width; // body pocket floor
assert(bear_z0 > nut_recess_d/2, "pocket too low for chamfer");

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

module pocket_ribs() {
    for(i=[0:crush_ribs-1]) rotate([0,0,i*360/crush_ribs])
        translate([bearing_od/2 - rib_bite, -rib_wide/2, bear_z0])
            cube([rib_bite + 0.4, rib_wide, bearing_width]);  // embeds 0.4 into wall
}

module wheel_body() {
  union() {
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
        // flange recess: from the inboard face down to the seat.
        // widens upward, so the seat ledge faces UP. support free.
        translate([0,0,flange_seat_z])
            cylinder(h=wheel_width-flange_seat_z+eps, d=flange_od+flange_clear);
        // body pocket under the flange seat
        translate([0,0,bear_z0]) cylinder(h=bearing_width+eps, d=bearing_od);
        // 45 deg chamfer transition down to the nut recess (no bridge)
        translate([0,0,bear_z0-(bearing_od-nut_recess_d)/2-eps])
            cylinder(h=(bearing_od-nut_recess_d)/2+0.15,
                     d1=nut_recess_d, d2=bearing_od+0.01);
        // nut recess: straight vertical hole to the bed
        translate([0,0,-eps]) cylinder(h=bear_z0+eps, d=nut_recess_d);
        // lightening holes, plain vertical holes in the base
        // between hub and gear
        for(i=[0:5]) rotate([0,0,i*60+30])
            translate([(hub_od/2+tip_r)/2,0,-eps])
                cylinder(h=base_thick+2*eps, d=lighten_d);
        // tread
        tread_cuts();
        // lead-in chamfer at the pocket mouth, guides the body in square
        translate([0,0,flange_seat_z-1])
            cylinder(h=1.01, d1=bearing_od, d2=bearing_od+1.6);
    }
    pocket_ribs();
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

module brim_ring() {
    difference() {
        cylinder(h=brim_h, d=wheel_od + 2*brim_w);
        translate([0,0,-eps]) cylinder(h=brim_h+2*eps, d=wheel_od - 2*brim_bite);
    }
}

if (part=="wheel") {
    wheel_body();
    if (brim) brim_ring();
    if (show_pinion)
        color("red") translate([pin_cd,0,wheel_width-16])
            linear_extrude(height=18) pinion_2d();
}
if (part=="tire") tpu_tire();
