// Parameters shared by Gmsh and GetDP: conductor, insulator and shield
// dimensions, and infinite-shell radii.

mm = 1e-3;

DefineConstant[
  d = {10, Min 1, Max 100, Step 1,
    Name "Parameters/Conductor spacing [mm]"}
  e = {4, Min 1, Max 10, Step 1,
    Name "Parameters/Conductor thickness [mm]"}
  h = {40, Min 5, Max 100, Step 1,
    Name "Parameters/Conductor height [mm]"}
  g = {15, Min 1, Max 10, Step 1,
    Name "Parameters/Dielectric thickness [mm]"}
  t = {1.5, Min 1, Max 10, Step 1,
    Name "Parameters/Shield thickness [mm]"}
];

// Go back to meters:
d = d * mm;
e = e * mm;
h = h * mm;
g = g * mm;
t = t * mm;

// Internal and external radii of "infinite" region
rInt = 4 * (d + e + g + t);
rExt = 5.5 * (d + e + g + t);
