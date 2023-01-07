include <Round-Anything/polyround.scad>
// Pick Gate to Notch
s = "gates/shell_front.stl";
//s = "gates/gate 0-3mm.stl";
//s = "gates/gate 0-6mm.stl";
//Basic Parameters
ang1 = 17;
ang2 = 73;
ang3 = 73;
ang4 = 17;
ang5 = 17;
ang6 = 73;
ang7 = 73;
ang8 = 17;
notch_rounding =0.25;
// Notch Style Parameters
straight = 0;
convexity = 0.05;
convexity_weight = 0.75;
flare_ang = 25;
// Advanced Parameters
notch_depth_double = 11.4;
diagonal_depth_double = 11.5;
notch_depth_single = 11.4;
diagonal_depth_single = 11.1;
//Adjust for your model's angle offset
// Default GCC offset is 3 degrees
off = 3;
// Probably don't need to adjust these
fs = 0.5;
diagonal_start_depth = 10;
notch_start_depth = 9;
flare_length = 3;
// --- FUNCTIONS AND MODULES ---
//Bezier Curves
// calculates the amount of points
// from distance of two points and fs
function fn(a, b) =
  round(sqrt(pow(a[0]-b[0],2)
  + pow(a[1]-b[1], 2))/fs);
// calculate each individual point
function b_pts(pts, n, idx) =
  len(pts)>2 ?
    b_pts([for(i=[0:len(pts)-2])
        pts[i]], n, idx) * n*idx
      + b_pts([for(i=[1:len(pts)-1])
        pts[i]], n, idx) * (1-n*idx)
    : pts[0] * n*idx
      + pts[1] * (1-n*idx);
// calculate fn() for given points,
// call b_pts() and concatenate points
function b_curv(pts) =
  let (fn=fn(pts[0], pts[len(pts)-1]))
    [for (i= [0:fn])
      concat(b_pts(pts, 1/fn, i))];
//Notches
function polarToXY(PPT)=
let(
X=cos(PPT[1])*PPT[0],
Y=sin(PPT[1])*PPT[0],
R=PPT[2]
)
[X,Y,R]
;
module single_notch(ang,mid,odd,straight){
phi = min(abs(ang-(mid-22.5)),abs(ang-(mid+22.5)));
r = notch_depth_single*cos(5.5)/cos(phi);
//diag start
p1 = polarToXY([diagonal_start_depth,mid-off,0]);
//diag cut
p2 = polarToXY([diagonal_depth_single,mid-off,0]);
//notch cut
p3 = polarToXY([r,ang-off,notch_rounding]);
// notch start
p4 = polarToXY([notch_start_depth,ang-off,0]);
mp_ang = (convexity_weight)*ang+(1-convexity_weight)*mid;
// flare
pf = (ang%90<45 && ang%90>0) ||(ang%90<0&&ang%90<-45)?
    [p3[0]-flare_length*cos(ang+flare_ang-off),p3[1]-flare_length*sin(ang+flare_ang-off),0]
    :[p3[0]-flare_length*cos(ang-flare_ang-off),p3[1]-flare_length*sin(ang-flare_ang-off),0];
//echo(atan2(p3[1],p3[0]));
//echo(atan2(p3[1]-pf[1],p3[0]-pf[0]));
mp_r = (1-convexity)*r;
bp =  polarToXY([mp_r,mp_ang-off,0]);   
//nmp=(p2+p3)/2;
//bp = nmp*(1-convexity);
//make curve
b_points=b_curv([p2,bp,p3]);
points = straight == 1 ? 
    [p1,p2,p3,pf,p4]
   :concat(b_points,[p1],[p4],[pf]);
linear_extrude(100)
polygon(polyRound(points,30));
}
module double_notch(a1,a2,mid,odd,straight){
phi1 = min(abs(a1-(mid-22.5)),abs(a1-(mid+22.5)));
phi2 = min(abs(a2-(mid-22.5)),abs(a2-(mid+22.5)));
// Gate is hexagonal so cut depth depends on angle
// This allows for consistent notch depths
r1 = notch_depth_double*cos(5.5)/cos(phi1);    
r2 = notch_depth_double*cos(5.5)/cos(phi2);    
//diag start
p1 = polarToXY([diagonal_start_depth,mid-off,0]);
//notch1 start
p2 = polarToXY([notch_start_depth,a1-off,0]);
//notch1 cut 
p3 = polarToXY([r1,a1-off,notch_rounding]);
//diag cut
p4 = polarToXY([diagonal_depth_double,mid-off,0]);
//notch2 cut 
p5 = polarToXY([r2,a2-off,notch_rounding]);
//notch2 start    
p6 = polarToXY([notch_start_depth,a2-off,0]);
pf1=[p3[0]-flare_length*cos(a1+flare_ang-off),p3[1]-flare_length*sin(a1+flare_ang-off),0];
pf2=[p5[0]-flare_length*cos(a2-flare_ang-off),p5[1]-flare_length*sin(a2-flare_ang-off),0];
mp_a1 = (convexity_weight)*a1+(1-convexity_weight)*mid;
mp_r1 = (1-convexity)*r1;
mp_a2 = (convexity_weight)*a2+(1-convexity_weight)*mid;
mp_r2 = (1-convexity)*r2;
bp1 =  polarToXY([mp_r1,mp_a1-off,0]);   
bp2 =  polarToXY([mp_r2,mp_a2-off,0]);   
//nmp1=(p3+p4)/2;
//bp1 = nmp1*(1-convexity);
//nmp2=(p4+p5)/2;
//bp2 = nmp2*(1-convexity);
b_points1=b_curv([p4,bp1,p3]);
b_points2=b_curv([p5,bp2,p4]);
points = straight == 1 ?
    [p1,p2,pf1,p3,p4,p5,pf2,p6]
    :concat([p1],[p2],[pf1],b_points1,b_points2,[pf2],[p6]);
linear_extrude(100)
polygon(polyRound(points,30));
}

//Actual Work
difference (){ 
import(s);
if (ang1!=0 && ang2!=0) double_notch(ang1,ang2,45,1,straight);
else{
    if (ang1!=0) single_notch(ang1,45,0,straight);
    else if (ang2!=0) single_notch(ang2,45,0,straight);
}
if (ang3!=0 && ang4!=0) double_notch(180-ang3,180-ang4,135,1,straight);
else{
    if (ang3!=0) single_notch(180-ang3,135,0,straight);
    else if (ang4!=0) single_notch(180-ang4,135,0,straight);
}
if (ang5!=0 && ang6!=0) double_notch(-1*(180-ang5),-1*(180-ang6),-135,1,straight);
else{
    if (ang5!=0) single_notch(-1*(180-ang5),-135,0,straight);
    else if (ang6!=0) single_notch(-1*(180-ang6),-135,0,straight);
}
if (ang7!=0 && ang8!=0) double_notch(-ang7,-ang8,-45,1,straight);
else{
    if (ang7!=0) single_notch(-ang7,-45,0,straight);
    else if (ang8!=0) single_notch(-ang8,-45,0,straight);
}
}

