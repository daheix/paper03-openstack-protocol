// Gmsh script describing the geometry of the same single-phase transformer as
// in tutorial 9, but in 3D.

SetFactory("OpenCASCADE");

Include "transfo_common.pro";

// The core is created by subtracting the inner box (the window) from the
// outer box:
Box(1) = {-wCore / 2, -hCore / 2, -thickCore / 2,
  wCore, hCore, thickCore};
Box(2) = {-wCore / 2 + wCoreLeg, -hCore / 2 + wCoreLeg, -thickCore / 2,
  wCore - 2 * wCoreLeg, hCore - 2 * wCoreLeg, thickCore};
BooleanDifference(3) = { Volume{1}; Delete; }{ Volume{2}; Delete; };

// We define a macro to create a coil, which expects three input parameters to
// be defined:
//  - "xCoil": leftmost position of the coil
//  - "wCoil": width of the coil
//  - "hCoil": height of the coil
Macro Coil
  r1 = news; // "news" returns the next available surface tag
  Rectangle(r1) = {xCoil, -hCoil / 2,
    thickCore / 2 + gapCoil + wCoil,
    2 * wCoil + 2 * gapCoil + wCoreLeg,
    thickCore + 2 * gapCoil + 2 * wCoil,
    wCoil / 2}; // rounded corner with radius "wCoil / 2"
  r2 = news;
  Rectangle(r2) = {xCoil + wCoil, -hCoil / 2 + wCoil,
    thickCore / 2 + gapCoil + wCoil,
    wCoreLeg + 2 * gapCoil,
    thickCore + 2 * gapCoil};
  // Subtract the inner rectangle from the outer rounded rectangle:
  d() = BooleanDifference{ Surface{r1}; Delete; }{ Surface{r2}; Delete; };
  // Rotate the resulting surface to create the base of the coil:
  Rotate {{1, 0, 0}, {0, -hCoil / 2, thickCore / 2 + gapCoil + wCoil}, -Pi / 2} {
    Surface{d(0)};
  }
  // Extrude the base along the y-axis:
  e() = Extrude{0, hCoil, 0}{ Surface{d(0)}; };
  // Create a "cut" in the coil to define an electrode. The cut surface
  // is needed in 3D so that the source current density inside the coil
  // can be derived from a single-valued scalar potential, with a unit
  // jump across the cut (see the .pro file).
  r3 = news;
  Rectangle(r3) = {xCoil, -hCoil / 2, 0, wCoil, hCoil};
  BooleanFragments { Surface{r3}; Delete; }{ Volume{e(1)}; Delete; }
Return

// Call the "Coil" macro twice to create the two coils:
xCoil = -wCore / 2 - gapCoil - wCoil1;
wCoil = wCoil1;
hCoil = hCoil1;
Call Coil;
xCoil = wCore / 2 - wCoreLeg - gapCoil - wCoil2;
wCoil = wCoil2;
hCoil = hCoil2;
Call Coil;

// Create the spherical shell region:
Sphere(10) = {0, 0, 0, JacRadiusInt};
Sphere(11) = {0, 0, 0, JacRadiusExt};

// Fragment all entities to get a conformal geometry:
Coherence;

// Use the "Closest" command to retrieve the regions of interest:
coil1() = Closest {-wCore / 2 - gapCoil - wCoil1 / 2, 0, 0} { Volume{:}; };
elec1() = Closest {-wCore / 2 - gapCoil - wCoil1 / 2, 0, 0} { Surface{:}; };
coil2() = Closest {wCore / 2 + gapCoil + wCoil2 / 2, 0, 0} { Volume{:}; };
elec2() = Closest {wCore / 2 - wCoreLeg - gapCoil - wCoil2 / 2, 0, 0} { Surface{:}; };
core() = Closest {0, hCore / 2 - mm, 0} { Volume{:}; };
airinf() = Closest {JacRadiusInt + mm, 0, 0} { Volume{:}; };

air() = Volume{:};
air() -= {airinf(0), core(0), coil1(0), coil2(0)};
bnd() = CombinedBoundary{ Volume{:}; };

// Assign mesh sizes:
DefineConstant[
  s = {3, Min 0.1, Max 10, Step 0.1,
    Name "Parameters/}Global mesh size factor"}
];
MeshSize{:} = 2 * mm * s;
MeshSize{ PointsOf{ Volume{airinf(0)}; } } = 8 * mm * s;

// Create physical groups:
Physical Volume("Air", 1) = air();
Physical Volume("AirInf", 2) = airinf(0);
Physical Volume("Coil1", 3) = coil1(0);
Physical Volume("Coil2", 4) = coil2(0);
Physical Volume("Core", 5) = core(0);
Physical Surface("Bnd", 10) = bnd();
Physical Surface("Electrode1", 11) = elec1(0);
Physical Surface("Electrode2", 12) = elec2(0);
