// This tutorial models the coupled magneto-thermal behaviour of a three-phase
// busbar system, consisting of three conductors carrying balanced AC currents
// inside an insulating enclosure surrounded by a grounded metallic shield.
//
// The magnetic part solves a magneto-quasistatic problem (as in tutorial 4) in
// the frequency domain, using an "a-v" formulation that combines the magnetic
// vector potential "a" with an electric scalar potential "v". The electric
// scalar potential is introduced to handle conductors with imposed currents or
// voltages -- this extends the approach from tutorial 4 (which only had an
// imposed source current density) and from tutorial 6 (which introduced global
// quantities in an electrostatic context).
//
// More precisely, since "div b = 0", we start by introducing the vector
// potential "a" such that "b = curl a". Faraday's equation leads to "curl e =
// -\partial_t b = -\partial_t curl a", i.e. "curl (e + \partial_t a) = 0". We
// can thus derive "e + \partial_t a" from a scalar electric potential "v" such
// that "e + \partial_t a = -grad v".
//
// Whereas in tutorial 4 we fixed the gradient to zero (leading to the modified
// vector potential "a-formulation"), here we keep it in the conductors so that,
// in each conducting region, the electric field is expressed as
//
//   e = -\partial_t a - grad v,
//
// where "grad v" is assumed to be a constant (region-wise) vector along the
// z-axis in this 2D model. The current density in each conductor is then
//
//   j = sigma e = sigma (-\partial_t a - grad v).
//
// Integrating "j" over the cross-section of a conductor yields the total
// current, which can be imposed as a constraint. Similarly, the voltage drop
// per unit length along "z" can be imposed or computed. This is the "a-v"
// formulation, where "v" is discretized with a single global degree of freedom
// per conducting region.
//
// The thermal part solves the steady-state heat equation (as in tutorial 2),
// with time-averaged Joule losses from the magnetic solution as a volumetric
// heat source. Convection boundary conditions evacuate the heat on the outer
// surfaces of the solid regions.
//
// The coupling arises because the electrical conductivity "sigma" depends on
// temperature, and the Joule losses depend on the current distribution (which
// depends on "sigma"). A fixed-point (Picard) iteration (see tutorial 3)
// alternates between the magnetic and thermal solves until convergence.

Group {
  // Physical regions:
  Cond_1 = Region[ 100 ];
  Cond_2 = Region[ 101 ];
  Cond_3 = Region[ 102 ];
  Conds = Region[ {Cond_1, Cond_2, Cond_3} ];
  Insulator = Region[ 200 ];
  Shield = Region[ 201 ];
  Air = Region[ 202 ];
  AirInf = Region[ 203 ];
  Surface_Inf = Region[ 300 ];
  Surface_Conv = Region[ 301 ];

  // Abstract magnetic regions:
  //  - "Vol_Mag": full domain for the magnetic problem
  //  - "Vol_C_Mag": conducting regions where eddy currents and/or imposed
  //    currents flow (both the three-phase conductors and the grounded shield)
  //  - "Vol_Inf_Mag": region with infinite shell geometric transformation (see
  //    tutorial 3)
  //  - "Sur_Neu_Mag": surface with non-homogeneous Neumann conditions (empty
  //    here)
  Vol_Mag = Region[ {Conds, Insulator, Shield, Air, AirInf} ];
  Vol_C_Mag = Region[ {Conds, Shield} ];
  Vol_Inf_Mag = Region[ AirInf ];
  Sur_Neu_Mag = Region[ {} ];

  // Abstract thermal regions:
  //  - "Vol_The": domain for the thermal problem (solid regions only)
  //  - "Sur_Neu_The": surface with non-homogeneous Neumann conditions (empty)
  //  - "Sur_Rob_The": surface with Robin (convection) boundary condition
  Vol_The = Region[ {Conds, Insulator, Shield} ];
  Sur_Neu_The = Region[ {} ];
  Sur_Rob_The = Region[ {Surface_Conv} ];
}

Function {
  DefineConstant[
    Current = {1400, Min 1, Max 10000, Step 1,
      Name "Parameters/0Current [A]"}
    f = {50, Min 1, Max 1000, Step 1,
      Name "Parameters/1Frequency"}
    NonLinear = {1, Choices{0, 1},
      Name "Parameters/3Temperature-dependent conductivity" }
  ];

  // Magnetic parameters:
  mu0 = 4 * Pi * 1e-7;
  nu[] = 1. / mu0;

  If(NonLinear)
    // Temperature-dependent electrical conductivity of the copper conductors:
    // the argument "$1" will receive the local temperature value at runtime,
    // which is passed through "sigma[{T}]" in the Formulation (see below). This
    // is the mechanism through which the thermal solution influences the
    // magnetic problem:
    sigma[ Conds ] = 5.8e7 / (1 + 0.00393 * ($1 - 20));
  Else
    // Temperature independent electrical conductivity, for comparison purposes:
    sigma[ Conds ] = 5.8e7;
  EndIf

  // The electrical conductivity of the shield is assumed to be temperature
  // independent:
  sigma[ Shield ] = 3.5e7;

  // "CoefGeo[]" encodes the out-of-plane extent implicit in a 2D model:
  //   - for a planar 2D model, "CoefGeo == L", the out-of-plane length along
  //     the z-axis;
  //   - for an axisymmetric model, "CoefGeo == 2 * Pi" (the full revolution).
  // Its role in the a-v formulation, and why its sign matters, will be
  // explained below. In the present 2D model we set "L = +1 m", so
  // per-unit-length quantities are recovered directly:
  CoefGeo[] = 1;

  // Thermal parameters -- "k" is the thermal conductivity, "h" the convection
  // heat-transfer coefficient and "T0" the ambient temperature:
  k[ Conds ] = 385;
  k[ Shield ] = 205;
  k[ Insulator ] = 1;
  h[] = 60;
  T0[] = 20;

  // Tolerances and maximum iterations for the magneto-thermal fixed-point loop,
  // in the nonlinear case:
  NLTolAbs = 1e-12;
  NLTolRel = 1e-6;
  NLIterMax = 20;
}

Constraint {
  // Homogeneous Dirichlet condition on the magnetic vector potential at infinity
  // (as in tutorials 3 and 4):
  { Name a_Mag_2D;
    Case {
      { Region Surface_Inf; Value 0; }
    }
  }

  // Imposed total current in each conductor. The three-phase balanced currents
  // are specified with 120 degree phase shifts using the built-in function
  // "F_Cos_wt_p[]{omega, phi}", which is interpreted as "Complex[Cos[phi],
  // Sin[phi]]" in the frequency domain (and as "Cos[omega * $Time + phi]" in
  // the time domain -- see tutorial 4 for a similar mechanism with
  // "F_Sin_wt_p[]"):
  { Name Current_Mag_2D;
    Case {
      { Region Cond_1; Value Current;
        TimeFunction F_Cos_wt_p[]{2 * Pi * f, 0}; }
      { Region Cond_2; Value Current;
        TimeFunction F_Cos_wt_p[]{2 * Pi * f, -2 * Pi / 3}; }
      { Region Cond_3; Value Current;
        TimeFunction F_Cos_wt_p[]{2 * Pi * f, 2 * Pi / 3}; }
    }
  }

  // The shield is grounded, i.e. zero voltage drop along the z-axis. This
  // allows induced (eddy) currents to flow freely in the shield, driven by the
  // time-varying magnetic flux:
  { Name Voltage_Mag_2D;
    Case {
      { Region Shield; Value 0; }
    }
  }

  // Initial temperature for the thermal problem:
  { Name T_The; Type Init;
    Case {
      { Region Vol_The; Value T0[]; }
    }
  }
}

// Import the values of "rInt" and "rExt" for the infinite shell Jacobian:
Include "busbar_common.pro";

Jacobian {
  { Name Vol;
    Case {
      // Use the infinite shell Jacobian on the annular region:
      { Region Vol_Inf_Mag; Jacobian VolSphShell{rInt, rExt}; }
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
        }
      }
    }
  }
}

Group {
  Dom_Hcurl_a_Mag_2D = Region[ {Vol_Mag, Sur_Neu_Mag} ];
  Dom_H1_T_The = Region[ {Vol_The, Sur_Neu_The, Sur_Rob_The} ];
}

FunctionSpace {
  // Magnetic vector potential, discretized as in tutorials 3 and 4 with
  // perpendicular edge basis functions "BF_PerpendicularEdge" associated with
  // the nodes of the mesh:
  { Name Hcurl_a_Mag_2D; Type Form1P;
    BasisFunction {
      { Name se; NameOfCoef ae; Function BF_PerpendicularEdge;
        Support Dom_Hcurl_a_Mag_2D; Entity NodesOf[All]; }
    }
    Constraint {
      { NameOfCoef ae; EntityType NodesOf; NameOfConstraint a_Mag_2D; }
    }
  }

  // The gradient of the electric scalar potential, "grad v", is discretized
  // with one global degree of freedom per conducting region using the
  // "BF_RegionZ" basis function. "BF_RegionZ" is the unit vector along the
  // z-axis -- constant and equal to "(0, 0, 1)" -- on each region in
  // "Vol_C_Mag", and zero everywhere else. It is the vector counterpart of the
  // scalar "BF_GroupOfNodes" basis function introduced in tutorial 6 for global
  // quantities.
  //
  // The finite element expansion of "grad v" thus reads
  //
  //   grad v = Sum_{r in Vol_C_Mag} ur_r sr_r(x, y)
  //
  // where "ur_r" is the (constant, complex-valued) z-component of the gradient
  // of the electric potential in region r, and "sr_r(x, y)" is the unit vector
  // along z, equal to 1 in region r and 0 elsewhere.
  //
  // As with the electrostatic global quantities in tutorial 6, the voltage
  // ("AliasOf") and the current ("AssociatedWith") are energy duals. The rule
  // of thumb when choosing which gets which type: the quantity that plays the
  // role of the primary degree of freedom -- the one the variational
  // formulation uses as test function -- is the "AliasOf"; its energy-dual (the
  // quantity that appears in the bilinear form paired with the test function)
  // is the "AssociatedWith". Accordingly, the GlobalTerm below pairs "Dof{I}"
  // (AssociatedWith) with "{U}" (AliasOf), exactly the way "GlobalTerm
  // [-Dof{Q}, {V}]" pairs charge with voltage in tutorial 6.
  { Name Hcurl_u_Mag_2D; Type Form1P;
    BasisFunction {
      // constant vector over the region, with only nonzero z-component
      { Name sr; NameOfCoef ur; Function BF_RegionZ;
        Support Vol_C_Mag; Entity Vol_C_Mag; }
    }
    GlobalQuantity {
      { Name Voltage; Type AliasOf; NameOfCoef ur; }
      { Name Current; Type AssociatedWith; NameOfCoef ur; }
    }
    Constraint {
      { NameOfCoef Voltage; EntityType Region; NameOfConstraint Voltage_Mag_2D; }
      { NameOfCoef Current; EntityType Region; NameOfConstraint Current_Mag_2D; }
    }
  }

  // Temperature, discretized with standard nodal (Lagrange) basis functions (as
  // in tutorial 2):
  { Name H1_T_The; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef Tn; Function BF_Node; Support Dom_H1_T_The;
        Entity NodesOf[All]; }
    }
    Constraint {
      { NameOfCoef Tn; EntityType NodesOf; NameOfConstraint T_The; }
    }
  }

}

Formulation {
  // Magneto-quasistatic a-v formulation.
  //
  // Using the constitutive law "h = nu b" together with "b = curl a" in
  // Ampere's equation, and plugging Ohm's law "j = sigma e" with "e =
  // -\partial_t a - grad v", we obtain
  //
  //   curl(nu curl a) = j = sigma e = -sigma \partial_t a - sigma grad v.
  //
  // In each conducting region, "grad v" is assumed to be constant, and zero
  // everywhere else. The weak a-v formulation then reads: find "a" and "v" such
  // that
  //
  //   (nu curl a, curl a')_Vol_Mag + (sigma \partial_t a, a')_Vol_C_Mag
  //     + (sigma grad v, a')_Vol_C_Mag = 0
  //
  //   - (sigma \partial_t a, ur')_Vol_C_Mag - (sigma grad v, ur')_Vol_C_Mag
  //     = I(ur')
  //
  // hold for all test functions "a'" and "ur'", with "I(ur') = I_r", the
  // current in conductor "r", for each "r" in "Vol_C_Mag". For each test
  // function "sr_r" (the global basis function for conductor "r"), the second
  // equation yields the circuit relation linking the voltage drop and the
  // current in region "r". In the first equation, as in tutorial 4, the
  // boundary term resulting from integration by parts vanishes since "a" is set
  // to 0 on the boundary of "Vol_Mag".
  //
  // In order to account for the out-of-plane length "L" of the model, we define
  // "grad v = ur / CoefGeo[]". Here "{ur}" is the discrete DoF attached to
  // "BF_RegionZ" (a constant z-vector per conducting region); dividing by
  // "CoefGeo[]" converts the region-wise voltage drop to the physical gradient
  // that appears in the PDE. "CoefGeo[]" plays two roles:
  //  - Everywhere "grad v" enters an integrand, it is written as "{ur} /
  //    CoefGeo[]", with "CoefGeo == L" in planar 2D and "CoefGeo == 2 * Pi" in
  //    axisymmetric. This is a modelling convention, not a Jacobian correction:
  //    the "Vol" (resp. "VolAxi") Jacobian already rescales each surface
  //    integrand to its 3D counterpart. So "CoefGeo" divides "{ur}" in
  //    "Integral" terms only where "grad v" appears explicitly.
  //  - The sign of "CoefGeo[]" lets the user flip the orientation of the
  //    current in a region (e.g. for a return conductor). This sign enters the
  //    circuit relation via the "GlobalTerm" with "Sign[CoefGeo[]]" below. In
  //    the present 2D model, "CoefGeo[] = 1", so the sign has no numerical
  //    effect -- it is kept so that the same formulation can be reused in
  //    models with oppositely-oriented conductors.
  { Name Magnetoquasistatics_av_2D; Type FemEquation;
    Quantity {
      { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
      { Name ur; Type Local; NameOfSpace Hcurl_u_Mag_2D; }
      { Name I; Type Global; NameOfSpace Hcurl_u_Mag_2D [Current]; }
      { Name U; Type Global; NameOfSpace Hcurl_u_Mag_2D [Voltage]; }

      // Declaring "T" in this formulation gives access to the temperature field
      // from the thermal FunctionSpace, which is needed to evaluate the
      // temperature-dependent conductivity sigma:
      { Name T; Type Local; NameOfSpace H1_T_The; }
    }
    Equation {
      Integral { [ nu[] * Dof{d a} , {d a} ];
        In Vol_Mag; Jacobian Vol; Integration Int; }
      // The coefficients in the magneto-quasistatic formulation will be
      // complex-valued, while those in the thermal formulation will be
      // real-valued. The "<T>[ ... ]" syntax instructs GetDP to evaluate the
      // expression inside in real arithmetic (in the FunctionSpace of "T"),
      // even though the formulation is complex-valued:
      Integral { DtDof [ sigma[<T>[{T}]] * Dof{a} , {a} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }
      Integral { [ sigma[<T>[{T}]] * Dof{ur} / CoefGeo[] , {a} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }

      Integral { DtDof [ sigma[<T>[{T}]] * Dof{a} , {ur} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }
      Integral { [ sigma[<T>[{T}]] * Dof{ur} / CoefGeo[] , {ur} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }
      // "Sign[CoefGeo[]]" accounts for a possible sign reversal of the current
      // direction (when "CoefGeo[] < 0"):
      GlobalTerm { [ Dof{I} * Sign[CoefGeo[]] , {U} ]; In Vol_C_Mag; }
    }
  }

  // Thermal formulation.
  //
  // We proceed as in tutorial 2, but in steady state and with a volume heat
  // source "Q". The steady-state thermal conduction problem is governed by
  //
  //    - div(k grad T) = Q,
  //
  // which, with the same convection boundary condition as in tutorial 2, leads
  // to the following weak form: find "T" such that
  //
  //   (k grad T, grad T')_Vol_The + (h (T - T0), T')_Sur_Rob_The
  //     = (Q, T')_Vol_C_Mag
  //
  // holds for all test functions "T'". In our magneto-thermal setting, "Q" is
  // the time-averaged Joule loss density over a period "[0, Tp]":
  //
  //   Q = 1/Tp \int_0^Tp sigma |e(t)|^2 dt = sigma/2 |E|^2
  //
  // with "E" the complex phasor of the electric field (the factor 1/2 comes
  // from time-averaging the squared sinusoid).

  { Name Thermal_T; Type FemEquation;
    Quantity {
      { Name T; Type Local; NameOfSpace H1_T_The; }

      // Declaring "{a}" and "{ur}" here gives access to the magnetic solution
      // (computed in the frequency domain) in order to evaluate Joule losses:
      { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
      { Name ur; Type Local; NameOfSpace Hcurl_u_Mag_2D; }
    }
    Equation {
      Integral { [ k[] * Dof{d T} , {d T} ];
        In Vol_The; Jacobian Vol; Integration Int; }

      Integral { [ h[] * Dof{T} , {T} ];
        In Sur_Rob_The; Jacobian Sur; Integration Int; }
      Integral { [ -h[] * T0[] , {T} ];
        In Sur_Rob_The; Jacobian Sur; Integration Int; }

      // The "<a>[ ... ]" syntax instructs GetDP to evaluate the expression
      // inside in complex arithmetic, even though the thermal formulation is
      // real-valued. Without it, only the real part of "{a}" and "{ur}" would
      // be used, which would give incorrect results. Note that, at the point
      // the thermal system is assembled, "{a}" and "{ur}" refer to the magnetic
      // solution that has already been computed (there is no "Dof" prefix),
      // i.e. they refer to known phasor fields. The expression "SquNorm[...]"
      // computes the squared modulus "|...|^2 = Re[...]^2 + Im[...]^2":
      Integral { [ -0.5 * sigma[{T}] * <a>[SquNorm[Dt[{a}] + {ur} / CoefGeo[]]],
          {T} ]; In Vol_C_Mag; Jacobian Vol; Integration Int; }
    }
  }
}

Resolution {
  // The coupled magneto-thermal resolution alternates between the magnetic and
  // thermal solves. The coupling is through:
  //  1) "sigma[{T}]": the conductivity in the magnetic problem depends on "T";
  //  2) Joule losses: the heat source "Q" in the thermal problem depends on the
  //     magnetic solution ("a", "ur").
  //
  // This is a fixed-point (Picard) iteration scheme: at each iteration, the
  // magnetic system is solved with the current temperature distribution, then
  // the thermal system is solved with the resulting Joule losses. The process
  // repeats until the magnetic residual converges (indicating self-consistency
  // of the two coupled problems).
  //
  // A monolithic coupling could also be implemented, where a single coupled
  // system is solved.
  //
  // If the NonLinear flag is not set, we disregard the temperature dependency
  // of copper conductivity and the coupled problem can be solved without
  // iterating.
  { Name MagThe;
    System {
      // The magnetic system is complex-valued and solved at a single frequency
      // (as in the frequency-domain case of tutorial 4):
      { Name Sys_Mag; NameOfFormulation Magnetoquasistatics_av_2D;
        Type Complex; Frequency f; }
      // The thermal system is real-valued:
      { Name Sys_The; NameOfFormulation Thermal_T; }
    }
    Operation {
      // Initialize the temperature to the initial condition "T0[]":
      InitSolution[Sys_The];

      // First solve: magnetic with the initial temperature, then thermal:
      Generate[Sys_Mag]; Solve[Sys_Mag];
      Generate[Sys_The]; Solve[Sys_The];

      If(NonLinear)
        // Re-generate the magnetic system with the updated temperature (which
        // changes sigma), and compute the initial residual:
        Generate[Sys_Mag];
        GetResidual[Sys_Mag, $res0];

        // Initialize runtime variables to track the residual and the iteration
        // count, then print out the absolute and relative residual:
        Evaluate[ $res = $res0, $iter = 0 ];
        Print[{$iter, $res, $res / $res0},
          Format "Residual %03g: abs %14.12e rel %14.12e"];

        // Iterate until convergence (same loop structure as in tutorial 3):
        While[$res > NLTolAbs && $res / $res0 > NLTolRel &&
          $res / $res0 <= 1 && $iter < NLIterMax]{
          Solve[Sys_Mag];
          Generate[Sys_The]; Solve[Sys_The];
          Generate[Sys_Mag]; GetResidual[Sys_Mag, $res];
          Evaluate[ $iter = $iter + 1 ];
          Print[{$iter, $res, $res / $res0},
            Format "Residual %03g: abs %14.12e rel %14.12e"];
        }
      EndIf

      SaveSolution[Sys_Mag];
      SaveSolution[Sys_The];
    }
  }
}

PostProcessing {
  // Post-processing for the magnetic formulation. Since the magnetic solution
  // is complex-valued, all quantities defined here are complex phasors:
  { Name Mag; NameOfFormulation Magnetoquasistatics_av_2D;
    Quantity {
      { Name a;
        Value {
          Term { [ {a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name az;
        Value {
          Term { [ CompZ[{a}] ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name b;
        Value {
          Term { [ {d a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name j;
        Value {
          Term { [ -sigma[<T>[{T}]] * (Dt[{a}] + {ur} / CoefGeo[]) ];
            In Vol_C_Mag; Jacobian Vol; }
        }
      }
      { Name JouleLosses;
        Value {
          Integral { [ 0.5 * sigma[<T>[{T}]] * SquNorm[Dt[{a}] + {ur} /
                CoefGeo[]] ]; In Vol_C_Mag; Jacobian Vol; Integration Int; }
        }
      }
      { Name U;
        Value {
          Term { [ {U} ]; In Vol_C_Mag; }
        }
      }
      { Name I;
        Value {
          Term { [ {I} ]; In Vol_C_Mag; }
        }
      }
    }
  }

  // Post-processing for the thermal formulation:
  { Name The; NameOfFormulation Thermal_T;
    Quantity {
      { Name T;
        Value {
          Term { [ {T} ]; In Vol_The; Jacobian Vol; }
        }
      }
    }
  }
}

PostOperation {
  { Name MapMag; NameOfPostProcessing Mag;
    Operation {
      Print[ az, OnElementsOf Vol_Mag, File "az.pos" ];
      Print[ b, OnElementsOf Vol_Mag, File "b.pos" ];
      Print[ j, OnElementsOf Vol_C_Mag, File "j.pos" ];
      // "RegionTable" outputs one row per region (instead of one row per
      // element), which is appropriate for global quantities:
      Print[ U, OnRegion Vol_C_Mag, File "U.txt", Format RegionTable ];
      Print[ I, OnRegion Vol_C_Mag, File "I.txt", Format RegionTable ];
    }
  }
  { Name MapThe; NameOfPostProcessing The;
    Operation {
      Print[ T, OnElementsOf Vol_The, File "T.pos" ];
    }
  }
}

// Setting a variable with the reserved name "GetDP/2PostOperationChoices"
// controls which PostOperations are performed by default by Gmsh when the
// model is run interactively. Here we request both "MapMag" and "MapThe",
// instead of just "MapMag" (the default):
DefineConstant[
  PostOp = {"MapMag, MapThe", Name "GetDP/2PostOperationChoices"}
];
