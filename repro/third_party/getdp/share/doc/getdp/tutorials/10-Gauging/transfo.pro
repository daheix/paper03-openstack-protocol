// This tutorial models the same single-phase transformer as in tutorial 9
// (primary winding driven by a voltage source, secondary winding feeding a
// selectable load), but in 3D. The frequency-domain magneto-quasistatic a-v
// formulation coupled with two circuits is essentially the same as in tutorial
// 9; what is genuinely new here is specific to the 3D setting:
//
//  - Gauging of the magnetic vector potential. In 3D the curl-curl operator
//    has a nontrivial null space (gradient fields), so "a" is not uniquely
//    determined by "b = curl a". A gauge condition is needed. Two strategies
//    are presented and can be selected at runtime via the "GaugeType"
//    parameter: tree-cotree gauging (the same scheme used in tutorial 8) and
//    Coulomb gauging through a scalar Lagrange multiplier.
//
//  - Source current density in the windings. Tutorial 9 modelled stranded
//    coils through a uniform current density "Ns / Sc * I * z_hat" pointing
//    along "z", which is straightforward because the 2D geometry has
//    translation invariance in that direction. In 3D the winding follows a
//    curved path around the core, so the current density must turn with it.
//    We obtain it by pre-computing, in each coil, a normalized scalar
//    potential "vs" that solves a homogeneous Laplace problem with a unit
//    jump across the electrode cut introduced in the .geo. The resulting
//    "js = -grad vs" is divergence-free by construction and integrates to one
//    across any cross-section. The actual source current density in each
//    coil is then enforced by multiplying this pre-computed distribution by
//    the global current quantity determined by the circuit equations.
//
//  - No more "CoefGeo[]". The 2D coefficient introduced in tutorial 7 to
//    encode the out-of-plane extent of the model (planar thickness or
//    "2 * Pi" for axisymmetry) is no longer needed: in 3D the geometry is
//    meshed in full, so no out-of-plane rescaling is required.
Include "transfo_common.pro";

Group {
  // Physical regions:
  Air = Region[ 1 ];
  AirInf = Region[ 2 ];
  Coil_1 = Region[ 3 ];
  Coil_2 = Region[ 4 ];
  Coils = Region[ {Coil_1, Coil_2} ];
  Core = Region[ 5 ];
  Bnd = Region[ 10 ];
  Electrode_1 = Region[ 11 ];
  Electrode_2 = Region[ 12 ];

  // Abstract regions:
  //  - "Vol_Mag": full magnetic domain
  //  - "Vol_S_Mag": stranded conductors (windings with Ns turns)
  //  - "Vol_Inf_Mag": region with infinite shell transformation
  //  - "Vol_Ele~{i}": i-th coil for source current density pre-calculation
  //  - "Sur_Electrode_Ele~{i}": electrode in i-th coil
  Vol_Mag = Region[ {Air, AirInf, Core, Coil_1, Coil_2} ];
  Vol_S_Mag = Region[ {Coil_1, Coil_2} ];
  Vol_Inf_Mag = Region[ AirInf ];
  NumCoils = 2;
  For i In {1 : NumCoils}
    // "~{i}" in the group names below will be transformed into "_1" when "i ==
    // 1" and "_2" when "i == 2" in the "For" loop. This is a general mechanism
    // in GetDP that can be applied not only to groups but to most object names
    // (constants, functions, constraints, function spaces, ...) in order to
    // create their names programmatically:
    Vol_Ele~{i} = Region[ Coil~{i} ];
    Sur_Electrode_Ele~{i} = Region[ Electrode~{i} ];
  EndFor

  // Circuit regions:
  E_in = Region[ 100 ];
  Z_out = Region[ 102 ];

  // Abstract circuit regions:
  //  - "Source_Cir": all voltage and current sources
  //  - "Resistance_Cir": all resistors
  //  - "Inductance_Cir": all inductors
  //  - "Capacitance_Cir": all capacitors
  Source_Cir = Region[ {E_in} ];
  DefineConstant[
    LoadType = {0, Choices {0="Resistance", 1="Inductance", 2="Capacitance"},
      Name "Parameters/2Load type"}
  ];
  If(LoadType == 0)
    Resistance_Cir = Region[ {Z_out} ];
  ElseIf(LoadType == 1)
    Inductance_Cir = Region[ {Z_out} ];
  Else
    Capacitance_Cir = Region[ {Z_out} ];
  EndIf
}

Function {
  DefineConstant[
    Voltage = {1, Min 1e-3, Max 10,
      Name "Parameters/0Primary voltage [V]"}
    f = {50, Min 0, Max 1e3, Step 1,
      Name "Parameters/1Frequency [Hz]"}
    Rval = {50, Min 1e-3, Max 50, Step 0.25, Visible (LoadType == 0),
      Name "Parameters/3Load resistance [Ohm]"}
    Lval = {1e-6, Min 1e-9, Max 0.1, Step 1e-3, Visible (LoadType == 1),
      Name "Parameters/3Load inductance [H]"}
    Cval = {1e-6, Min 1e-9, Max 0.1, Step 1e-4, Visible (LoadType == 2),
      Name "Parameters/3Load capacitance [F]"}
    murCore = {2000, Min 1, Max 10000, Step 1,
      Name "Parameters/4Core relative permeability"}
    dlam = {0.35e-3, Min 0.1e-3, Max 1e-3, Step 0.05e-3,
      Name "Parameters/5Lamination thickness [m]"}
    kh = {100, Min 10, Max 500, Step 10,
      Name "Parameters/6Hysteresis coeff [W m^-3 T^-2 s]"}
    GaugeType = {0, Choices {0="Tree-Cotree", 1="Coulomb"},
      Name "Parameters/7Gauge type"}
  ];

  mu0 = 4e-7 * Pi;
  nu[ Air ] = 1 / mu0;
  nu[ AirInf ] = 1 / mu0;

  // Same modelling of ferromagnetic laminations as in tutorial 9:
  nu_r = 1 / (murCore * mu0);
  sigma_iron = 2e6;
  nu_i = kh / Pi + sigma_iron * (2 * Pi * f) * dlam^2 / 12;
  nu[ Core ] = Complex[nu_r, nu_i];

  // Number of turns "Ns" of each coil:
  Ns[ Coil_1 ] = 100;
  Ns[ Coil_2 ] = 200;

  nu[ Coils ] = 1 / mu0;
  sigma[ Coils ] = 5.8e7;

  Resistance[ Z_out ] = Rval;
  Inductance[ Z_out ] = Lval;
  Capacitance[ Z_out ] = Cval;
}

Constraint {
  { Name a_Mag;
    Case {
      { Region Bnd; Value 0; }
    }
  }

  // Tree-cotree gauging constraint on the vector potential "a" (only used when
  // "GaugeType == 0"); "a" is set to zero on the edges of a spanning tree of
  // the mesh; the "SubRegion Bnd" anchors the tree on the outer boundary, where
  // the homogeneous Dirichlet boundary condition "a_Mag" is imposed:
  { Name a_Gauge_Mag;
    Case {
      { Region Vol_Mag ; SubRegion Bnd; Value 0.; }
    }
  }

  // Boundary condition for the Coulomb gauge multiplier "xi" (only used when
  // "GaugeType == 1"):
  { Name xi_Mag;
    Case {
      // N.B.: we are only interested in the gradient of "xi", so we can set "xi"
      // to any value on the boundary; here we choose zero as it allows for an
      // easier mixed formulation (see explanations in the "Formulation" below):
      { Region Bnd; Value 0; }
    }
  }

  // No imposed current or voltage in the magnetic formulation -- the voltage
  // source is imposed in the circuit as in tutorial 9:
  { Name Current_Mag;
    Case {
    }
  }
  { Name Voltage_Mag;
    Case {
    }
  }

  { Name Current_Cir ;
    Case {
    }
  }

  { Name Voltage_Cir ;
    Case {
      { Region E_in; Value Voltage; TimeFunction F_Cos_wt_p[]{2 * Pi * f, 0}; }
    }
  }

  // Contrary to the massive conductor case (see tutorial 8), the global basis
  // function for circuit coupling is not associated with the electrodes
  // anymore, but directly with the regions in "Vol_S_Mag", i.e., with "Coil_1"
  // and "Coil_2", through the use of the pre-computed source current density
  // with "BF_Global" in the "Hregion_vs_Mag" function space (see below):
  { Name ElectricalCircuit ; Type Network ;
    Case Circuit_1 {
      { Region E_in; Branch {1, 2}; }
      { Region Coil_1; Branch {2, 1} ; }
    }
    Case Circuit_2 {
      { Region Coil_2; Branch {1, 2} ; }
      { Region Z_out; Branch {2, 1}; }
    }
  }
}

Jacobian {
  { Name Vol;
    Case {
      { Region All; Jacobian Vol; }
    }
  }
  { Name Sur;
    Case {
      { Region All; Jacobian Sur; }
    }
  }
}

Integration {
  { Name Int;
    Case {
      { Type Gauss;
        Case {
          { GeoElement Line; NumberOfPoints 4; }
          { GeoElement Triangle; NumberOfPoints 4; }
          { GeoElement Tetrahedron; NumberOfPoints 4; }
        }
      }
    }
  }
}

Group {
  DefineGroup[ Source_Cir, Resistance_Cir, Inductance_Cir, Capacitance_Cir ];
  Dom_Cir = Region[ {Source_Cir, Resistance_Cir, Inductance_Cir,
      Capacitance_Cir} ];
}

// Pre-computation of the source current density distribution in each coil. The
// scalar potential "vs" solves a homogeneous Laplace problem on the coil
// volume, with a unit jump across the electrode (the cut introduced in the
// .geo). The resulting field "js = -grad(vs)" is therefore divergence-free and,
// by construction, integrates to one across any cross-section. Below, each "js"
// field will be multiplied by the net current in Coil~{i} to model the actual
// current density distribution in the coil.
//
// Note that "js" is not exactly uniform across the cross-section: like a DC
// current in a homogeneous solid conductor of the same shape, it concentrates
// on the inner side of bends, where the current path is shorter. For a stranded
// winding (whose ideal current density would be uniform along the wire axis,
// "js = tau / Sc" with "tau" the unit tangent), this is therefore an
// approximation. Alternatives include prescribing "js" analytically (only
// practical for simple shapes like straight or circular coils), computing it
// from a magnetostatic problem with a known driving current (e.g. via
// Biot-Savart for line segments), or homogenizing the winding. The Laplace
// approach used here is fully general and divergence-free by construction.

For i In {1 : NumCoils}

  Constraint {
    // We enforce unit current across each coil's electrode
    { Name UnitCurrent~{i};
      Case {
        { Region Sur_Electrode_Ele~{i}; Type Assign; Value 1; }
      }
    }
  }

  FunctionSpace {
    { Name H1_vs~{i}; Type Form0;
      BasisFunction {
        { Name sn; NameOfCoef vn; Function BF_Node;
          Support Vol_Ele~{i};
          Entity NodesOf[ All, Not Sur_Electrode_Ele~{i} ]; }
        // We restrict the support of the global basis function to the positive
        // side of the electrode, i.e. the side where the electrode normal
        // points, using "ElementsOf[ ..., OnPositiveSideOf ...]". Since the
        // electrode surface "Sur_Electrode_Ele~{i}" is connected on both sides
        // to the same coil volume "Coil~{i}", this is necessary to properly set
        // up the discontinuity of "vs": the negative side of the electrode in
        // "Coil~{i}" will not be part of the support, hence the global function
        // will evaluate to zero there.
        //
        // As an alternative, we could have cut each "Coil~{i}" volume into two
        // parts, and restricted the support of the global function to one of
        // the parts.
        { Name sf; NameOfCoef vf; Function BF_GroupOfNodes;
          Support ElementsOf[Vol_Ele~{i}, OnPositiveSideOf Sur_Electrode_Ele~{i}];
          Entity GroupsOfNodesOf[ Sur_Electrode_Ele~{i} ]; }
      }
      GlobalQuantity {
        { Name Voltage; Type AliasOf; NameOfCoef vf; }
        { Name Current; Type AssociatedWith; NameOfCoef vf; }
      }
      Constraint {
        { NameOfCoef Current; EntityType GroupsOfNodesOf;
          NameOfConstraint UnitCurrent~{i}; }
      }
    }
  }

  Formulation {
    { Name Electrokinetics_vs~{i}; Type FemEquation;
      Quantity {
        { Name vs; Type Local; NameOfSpace H1_vs~{i}; }
        { Name I; Type Global; NameOfSpace H1_vs~{i} [Current]; }
        { Name V; Type Global; NameOfSpace H1_vs~{i} [Voltage]; }
      }
      Equation {
        Integral { [ Dof{d vs} , {d vs} ];
          In Vol_Ele~{i}; Jacobian Vol; Integration Int; }
        GlobalTerm { [ Dof{I} , {V} ]; In Sur_Electrode_Ele~{i}; }
      }
    }
  }

  Resolution {
    // The "Ele~{i}" resolutions will be triggered automatically in a
    // pre-resolution phase, due to the "BF_Global" definition below; we hide
    // these resolutions from the list of available resolutions with the "Hidden
    // 1" option:
    { Name Ele~{i}; Hidden 1;
      System {
        { Name Sys_Ele; NameOfFormulation Electrokinetics_vs~{i}; }
      }
      Operation {
        Generate[Sys_Ele]; Solve[Sys_Ele];
      }
    }
  }

EndFor

FunctionSpace {

  // Function space for the magnetic vector potential "a". In 3D, the curl-curl
  // operator has a non-trivial kernel: since "curl(grad(phi)) = 0", any "a +
  // grad(phi)" gives the same flux density "b = curl(a)" and the same curl-curl
  // energy, so "a" is indeterminate up to gradients of arbitrary scalars "phi
  // in H1_0". A gauge condition is needed to obtain a unique solution:
  //  - Tree-cotree gauging ("GaugeType == 0"): pin "ae" to zero on the edges of
  //    a spanning tree of the mesh, rooted on the outer boundary
  //    ("EntitySubType StartingOn"). The gradient null space is spanned exactly
  //    by the tree edges (modulo boundary), so this kills it without affecting
  //    the physical solution. This constraint is directly implemented in the
  //    "Hcurl_a_Mag" space.
  //  - Coulomb gauging ("GaugeType == 1"): the gauge is imposed weakly in the
  //    formulation (see explanations in the "Formulation" below), thanks to a
  //    Lagrange multiplier "xi" in the "H1_xi_Mag" space.

  { Name Hcurl_a_Mag; Type Form1;
    BasisFunction {
      { Name se; NameOfCoef ae; Function BF_Edge;
        Support Vol_Mag; Entity EdgesOf[All]; }
    }
    Constraint {
      { NameOfCoef ae; EntityType EdgesOf; NameOfConstraint a_Mag; }
      If(GaugeType == 0)
        { NameOfCoef ae; EntityType EdgesOfTreeIn; EntitySubType StartingOn;
          NameOfConstraint a_Gauge_Mag; }
      EndIf
    }
  }

  If(GaugeType == 1)
    // We introduce a scalar Lagrange multiplier "xi" in H1_0 to enforce the
    // Coulomb gauge constraint; see explanations in the "Formulation" below.
    { Name H1_xi_Mag ; Type Form0 ;
      BasisFunction {
        { Name sn ; NameOfCoef xin ; Function BF_Node ;
          Support Vol_Mag; Entity NodesOf[All]; }
      }
      Constraint {
        { NameOfCoef xin; EntityType NodesOf; NameOfConstraint xi_Mag; }
      }
    }
  EndIf

  // Function space for the stranded-conductor global DoFs: one current (and its
  // dual voltage) per coil. Each basis function is the entire spatial
  // distribution of "vs" pre-computed by "Electrokinetics_vs~{i}" on the
  // corresponding "Coil~{i}", and the associated coefficient "ir" is the actual
  // current flowing through that coil.
  { Name Hregion_vs_Mag; Type Form0;
    BasisFunction {
      { Name sr; NameOfCoef ir;
        // "BF_Global" builds a basis function from a quantity computed by
        // another formulation -- here the unit-current source distribution
        // "-grad(vs)" pre-computed for each coil. The number of global basis
        // functions ("NumCoils == 2") should coincide with the number of
        // regions in "Group Vol_S_Mag" ("Coil_1" and "Coil_2"). The special
        // syntax "Electrokinetics_vs {NumCoils}" for the "Formulation" expands
        // to "Electrokinetics_vs_1" and "Electrokinetics_vs_2", matched
        // one-to-one with the regions of "Group Vol_S_Mag". "Ele {NumCoils}"
        // expands in the same way to "Ele_1" and "Ele_2" for the "Resolution":
        Function BF_Global {
          Quantity vs; Formulation Electrokinetics_vs {NumCoils};
          Group Vol_S_Mag; Resolution Ele {NumCoils};
        };
        // Each global basis function is directly associated with a "Global"
        // entity, i.e. each region in "Vol_S_Mag":
        Support Vol_S_Mag; Entity Global [Vol_S_Mag]; }
    }
    // "Current" is an alias of the coefficient "ir" (so "Current" is directly
    // the coil's current). "Voltage" is the dual global quantity associated
    // with "ir", representing the coil's terminal voltage; the link between
    // them is established by the "GlobalTerm" in the formulation and closed by
    // the "Network" constraint.
    GlobalQuantity {
      { Name Current; Type AliasOf; NameOfCoef ir; }
      { Name Voltage; Type AssociatedWith; NameOfCoef ir; }
    }
    // Both globals are left free here (cf. the empty "Current_Mag" and
    // "Voltage_Mag" constraints above): their runtime values are set by the
    // circuit equations.
    Constraint {
      { NameOfCoef Current; EntityType Global; NameOfConstraint Current_Mag; }
      { NameOfCoef Voltage; EntityType Global; NameOfConstraint Voltage_Mag; }
    }
  }

  { Name Hregion_i_Cir; Type Scalar;
    BasisFunction {
      { Name sr; NameOfCoef ir; Function BF_Region;
        Support Dom_Cir; Entity Dom_Cir; }
    }
    GlobalQuantity {
      { Name Current; Type AliasOf; NameOfCoef ir; }
      { Name Voltage; Type AssociatedWith; NameOfCoef ir; }
    }
    Constraint {
      { NameOfCoef Voltage; EntityType Region; NameOfConstraint Voltage_Cir; }
      { NameOfCoef Current; EntityType Region; NameOfConstraint Current_Cir; }
    }
  }

}

Formulation {
  { Name Magnetoquasistatics_av; Type FemEquation;
    Quantity {
      { Name a; Type Local; NameOfSpace Hcurl_a_Mag; }
      If(GaugeType == 1)
        { Name xi ; Type Local ; NameOfSpace H1_xi_Mag; }
      EndIf

      { Name vs; Type Local ; NameOfSpace Hregion_vs_Mag; }
      { Name Is; Type Global; NameOfSpace Hregion_vs_Mag [Current]; }
      { Name Us; Type Global; NameOfSpace Hregion_vs_Mag [Voltage]; }

      { Name Iz; Type Global; NameOfSpace Hregion_i_Cir [Current]; }
      { Name Uz; Type Global; NameOfSpace Hregion_i_Cir [Voltage]; }
    }
    Equation {
      Integral { [ nu[] * Dof{d a} , {d a} ];
        In Vol_Mag; Jacobian Vol; Integration Int; }

      // The Coulomb gauge weakly imposes div(a) = 0 via a Lagrange multiplier
      // saddle-point formulation. It picks, within each equivalence class "a +
      // grad(H1_0)", the unique representative L^2-orthogonal to the kernel:
      //
      //   (a, grad(xi')) = 0,   for all xi' in H1_0                 (*)
      //
      // By integration by parts ("xi' = 0" on "Bnd" cancels the boundary term),
      // (*) is equivalent to the variational form of "div(a) = 0", hence the
      // name.
      //
      // The constraint (*) is enforced by introducing a Lagrange multiplier "xi
      // in H1_0" and forming the Lagrangian
      //
      //   L(a, xi) = (1/2) * (nu * curl(a), curl(a)) - (j, a) + (a, grad(xi)).
      //
      // The two stationarity conditions give the saddle-point system. Variation
      // in "a" (replace "a" by "a + eps * a'", differentiate "L" with respect
      // to "eps" and set to zero at "eps = 0") gives, for any test direction
      // "a'", the augmented curl-curl equation
      //
      //   (nu * curl(a), curl(a')) + (grad(xi), a') = (j, a')       (1)
      //
      // The same procedure for "xi" affects only the multiplier-coupling term
      // and gives the gauge constraint
      //
      //   (a, grad(xi')) = 0                                        (2)
      //
      // (The term "(grad(xi), a')" in (1) is the transpose of "(a, grad(xi'))"
      // in (2), making the off-diagonal blocks of the block system transposes
      // of each other and the system symmetric.)
      //
      // Note: an "augmented Lagrangian" variant adds a penalty term "(gamma /
      // 2) * (div(a), div(a))" to "L", contributing an extra "gamma * (div(a),
      // div(a'))" to equation (1). With "gamma > 0" this improves the
      // conditioning of the otherwise indefinite system at the cost of tuning
      // "gamma"; the implementation below uses the bare Lagrangian ("gamma ==
      // 0"):
      If(GaugeType == 1)
        Integral { [ Dof{a}, {d xi} ] ;
          In Vol_Mag; Jacobian Vol; Integration Int; }
        Integral { [ Dof{d xi}, {a} ] ;
          In Vol_Mag; Jacobian Vol; Integration Int; }
      EndIf

      // The pre-computed source distribution "-grad(vs)" is normalized to a
      // unit current across the cross-section; the "Ns" factor scales it up to
      // the actual current density of the Ns-turn winding. The minus sign on
      // the dual term reflects "j_unit = -grad(vs)": the flux linkage "Lambda =
      // Ns * (a, j_unit) = -Ns * (a, grad(vs))" and its time derivative (the
      // back-EMF in the voltage equation) thus carry the opposite sign of the
      // source term:
      Integral { [ Ns[] * Dof{d vs} , {a} ];
        In Vol_S_Mag; Jacobian Vol; Integration Int; }

      Integral { DtDof[ -Ns[] * Dof{a} , {d vs} ];
        In Vol_S_Mag; Jacobian Vol; Integration Int; }

      // DC resistance of the winding. The "Ns^2" factor comes from Ns turns in
      // series, each one with cross-section Sc/Ns and length proportional to
      // Ns, i.e. R_total = Ns^2 * L / (sigma * Sc):
      Integral { [ Ns[]^2 / sigma[] * Dof{d vs} , {d vs} ];
        In Vol_S_Mag; Jacobian Vol; Integration Int; }

      GlobalTerm { [ Dof{Us} , {Is} ]; In Vol_S_Mag; }

      // The circuit coupling is handled in the same way as in tutorials 8 and
      // 9:
      GlobalTerm { [ Dof{Uz} , {Iz} ]; In Resistance_Cir; }
      GlobalTerm { [ Resistance[] * Dof{Iz} , {Iz} ]; In Resistance_Cir; }

      GlobalTerm { [ Dof{Uz} , {Iz} ]; In Inductance_Cir; }
      GlobalTerm { DtDof [ Inductance[] * Dof{Iz} , {Iz} ]; In Inductance_Cir; }

      GlobalTerm { [ Dof{Iz} , {Iz} ]; In Capacitance_Cir; }
      GlobalTerm { DtDof [ Capacitance[] * Dof{Uz} , {Iz} ]; In Capacitance_Cir; }

      GlobalEquation {
        Type Network; NameOfConstraint ElectricalCircuit;
        { Node {Is}; Loop {Us}; Equation {Us}; In Vol_S_Mag; }
        { Node {Iz}; Loop {Uz}; Equation {Uz}; In Dom_Cir; }
      }
    }
  }
}

Resolution {
  { Name Mag;
    System {
      { Name Sys_Mag; NameOfFormulation Magnetoquasistatics_av;
        Type Complex; Frequency f;
      }
    }
    Operation {
      Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
    }
  }
}

PostProcessing {
  { Name Mag; NameOfFormulation Magnetoquasistatics_av;
    Quantity {
      { Name a;
        Value {
          Term { [ {a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name vs;
        Value {
          Term { [ {vs} ]; In Vol_S_Mag; Jacobian Vol; }
        }
      }
      { Name js;
        Value {
          Term { [ - {d vs} ]; In Vol_S_Mag; Jacobian Vol; }
        }
      }
      { Name b;
        Value {
          Term { [ {d a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name U; Value {
          Term { [ {Uz} ]; In Dom_Cir; }
          Term { [ {Us} ]; In Vol_S_Mag; }
        }
      }
      { Name I; Value {
          Term { [ {Iz} ]; In Dom_Cir; }
          Term { [ {Is} ]; In Vol_S_Mag; }
        }
      }
      { Name NormU; Value {
          Term { [ Norm[{Uz}] ]; In Dom_Cir; }
          Term { [ Norm[{Us}] ]; In Vol_S_Mag; }
        }
      }
      { Name NormI; Value {
          Term { [ Norm[{Iz}] ]; In Dom_Cir; }
          Term { [ Norm[{Is}] ]; In Vol_S_Mag; }
        }
      }
    }
  }
}


PostOperation {
  { Name Map; NameOfPostProcessing Mag;
    Operation {
      Print[ vs, OnElementsOf Vol_S_Mag, Format Gmsh, File "vs.pos" ];
      Print[ js, OnElementsOf Vol_S_Mag, Format Gmsh, File "js.pos" ];
      Print[ a, OnElementsOf Vol_Mag, Format Gmsh, File "a.pos" ];
      Print[ b, OnElementsOf Vol_Mag, Format Gmsh, File "b.pos" ];
      Echo[ "E_in", Format Table, File "UI.txt" ];
      Print[ U, OnRegion E_in, Format FrequencyTable, File > "UI.txt"];
      Print[ I, OnRegion E_in, Format FrequencyTable, File > "UI.txt"];
      Echo[ "Z_out", Format Table, File > "UI.txt" ];
      Print[ U, OnRegion Z_out, Format FrequencyTable, File > "UI.txt"];
      Print[ I, OnRegion Z_out, Format FrequencyTable, File > "UI.txt"];
      Print[ NormU, OnRegion E_in, Format Table, File "",
        SendToServer "}Output/0|V_in| [V]"{0} ];
      Print[ NormI, OnRegion E_in, Format Table, File "",
        SendToServer "}Output/1|I_in| [A]"{0} ];
      Print[ NormU, OnRegion Z_out, Format Table, File "",
        SendToServer "}Output/2|V_out| [V]"{0} ];
      Print[ NormI, OnRegion Z_out, Format Table, File "",
        SendToServer "}Output/3|I_out| [A]"{0} ];
    }
  }
}
