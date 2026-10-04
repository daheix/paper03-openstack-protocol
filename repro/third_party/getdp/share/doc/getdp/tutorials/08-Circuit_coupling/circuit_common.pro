// Parameters shared by Gmsh and GetDP: model dimension and conductor
// thickness.

DefineConstant[
  dim = {2, Choices{2="2D", 3="3D"},
    Name "Parameters/0Model dimension"}
  thick = {5, Min 0.1, Max 10, Step 0.1,
    Name "Parameters/Thickness [mm]"}
];

// back to meters:
mm = 1e-3;
thick = thick * mm;
