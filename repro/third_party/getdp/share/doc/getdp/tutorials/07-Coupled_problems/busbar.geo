// Gmsh script describing the geometry of a three-phase busbar: three
// rectangular conductors inside an insulating enclosure surrounded by a
// grounded metallic shield, embedded in an air region with an infinite shell
// for the unbounded domain (see tutorial 3).

SetFactory("OpenCASCADE");

// Include the file with shared parameters, so that the same values are used
// here and in "busbar.pro":
Include "busbar_common.pro";

// Three rectangular conductors carrying balanced three-phase currents. The
// conductors are placed side by side, separated by a distance d, each with
// width e and height h:
For i In {1:3}
  Rectangle(i) = {-d - 1.5 * e + (i - 1) * (e + d), -h / 2, 0, e, h};
EndFor

// Insulation surrounding the three conductors, with a gap g on each side:
xx = -d - 1.5 * e - g;
yy = -h / 2 - g;
ww = 2 * d + 3 * e + 2 * g;
Rectangle(4) = {xx, yy, 0, ww, h + 2 * g};

// Metallic shield (thickness t) around the insulation:
Rectangle(5) = {xx - t, yy - t, 0, ww + 2 * t, h + 2 * g + 2 * t};

// Air region (disk) and infinite ring for the VolSphShell transformation (see
// tutorial 3); rInt and rExt are defined in "busbar_common.pro":
Disk(6) = {0, 0, 0, rInt};
Disk(7) = {0, 0, 0, rExt};

// Make all overlapping surfaces conformal (see tutorial 3):
Coherence;

// Mesh size constraints:
MeshSize { PointsOf{ Surface{6, 7}; } } = h / 5;
MeshSize { PointsOf{ Surface{4, 5}; } } = e / 3;
MeshSize { PointsOf{ Surface{1:3}; } } = e / 5;

// Physical groups:
Physical Surface("Conductor 1", 100) = {1};
Physical Surface("Conductor 2", 101) = {2};
Physical Surface("Conductor 3", 102) = {3};
Physical Surface("Insulator", 200) = {4};
Physical Surface("Shield", 201) = {5};
Physical Surface("Air", 202) = {6};
Physical Surface("Infinite shell", 203) = {7};

// Outermost boundary for the homogeneous Dirichlet boundary condition on the
// magnetic vector potential:
Physical Curve("Infinity", 300) = CombinedBoundary{ Surface{:}; };

// Boundary of all solid regions (conductors, insulator and shield) for the
// convection (Robin) boundary condition in the thermal problem:
Physical Curve("Convection", 301) = CombinedBoundary{ Surface{1:5}; };
