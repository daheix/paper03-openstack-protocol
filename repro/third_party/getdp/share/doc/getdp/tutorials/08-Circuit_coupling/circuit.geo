// Gmsh script describing the geometry of two rectangular conductors. In 2D the
// model consists of two rectangles (cross-sections of the conductors). In 3D
// the rectangles are extruded along z to form volumes, and the bottom and top
// surfaces of each conductor are identified as separate physical groups: these
// will serve as electrodes in the 3D circuit coupling.

SetFactory("OpenCASCADE");

Include "circuit_common.pro";

DefineConstant[
  w1 = {1, Min 0.1, Max 10, Step 0.1,
    Name "Parameters/Cond1 width [mm]"}
  w2 = {2, Min 0.1, Max 10, Step 0.1,
    Name "Parameters/Cond2 width [mm]"}
  s = {1, Min 0.1, Max 10, Step 0.1,
    Name "Parameters/}Global mesh size factor"}
];

w1 = w1 * mm;
w2 = w2 * mm;
h = 5 * mm;

Rectangle(1) = {0, 0, 0, w1, h};
Rectangle(2) = {w1 + 1 * mm, 0, 0, w2, h};

If(dim == 3)
  // Extrude both rectangles along z (see tutorial 2):
  left() = Extrude{0, 0, thick}{ Surface{1}; };
  cond1 = left(1);
  right() = Extrude{0, 0, thick}{ Surface{2}; };
  cond2 = right(1);
Else
  cond1 = 1;
  cond2 = 2;
EndIf

MeshSize{:} = 0.2 * mm * s;

bnd() = CombinedBoundary{ GeoEntity{dim}{:}; };

Physical GeoEntity{dim}("Conductor 1", 100) = cond1;
Physical GeoEntity{dim}("Conductor 2", 101) = cond2;
Physical GeoEntity{dim - 1}("Boundary", 200) = bnd();

If(dim == 3)
  // The bottom and top surfaces of each conductor are needed as electrode
  // surfaces for the 3D a-v formulation with circuit coupling. Surface tag "1"
  // is the original rectangle (bottom of cond1), and "left(0)" is the top
  // surface created by the extrusion. Similarly for cond2:
  Physical Surface("Bottom left", 300) = 1;
  Physical Surface("Top left", 301) = left(0);
  Physical Surface("Bottom right", 302) = 2;
  Physical Surface("Top right", 303) = right(0);
EndIf
