// This tutorial computes the magnetic field produced by an AC current in the
// same electromagnet as the one considered in tutorial 3 with a DC current.
//
// Building on the magnetostatic setting of tutorial 3, we extend Maxwell-Ampere
// to include a time-varying current density "curl h = j" (still without the
// displacement current), add the Faraday equation "curl e = -\partial_t b"
// relating the time derivative of "b" to the curl of the electric field "e",
// and close the system with Ohm's law "j = sigma e", with "sigma" the electric
// conductivity. The magnetic symbols ("h", "b", "mu", "nu = 1/mu") keep the
// same meaning as in tutorial 3. This is the magneto-quasistatic (or
// "magnetodynamic") regime. In the coil of the electromagnet we assume that
// eddy currents can be neglected and we simply impose a source current density
// "j = js". This is a standard modelling choice for "stranded" coils made of
// many thin insulated wires: each wire is thin compared to the skin depth,
// which prevents eddy loops from forming inside the coil. The assumption would
// no longer be valid for a massive ("solid") conductor (see tutorial 7).
//
// We can introduce a vector magnetic potential "a" such that "b = curl a" and
// "e = -\partial_t a", that satisfies both Gauss' law and Faraday's
// equation. We call this the "modified" vector potential because the usual
// definition "e = -\partial_t a - grad v" has been simplified by implicitly
// fixing the electric scalar potential "v" to zero -- equivalently, we have
// chosen a gauge that absorbs "grad v" into "a". This is a valid choice
// whenever the current is imposed (as here) rather than driven by a voltage.
// In tutorial 7 we will reintroduce "v" to allow prescribing a voltage drop or
// computing it from an imposed current, using the so-called "a-v" formulation.
//
// Plugging this vector potential into Ampere's equation and using the
// constitutive laws leads to
//
//   curl(nu curl a) + sigma \partial_t a = js
//
// where "nu = 1/mu" is the magnetic reluctivity. The right-hand side is the
// imposed (source) current density; on the left-hand side, "sigma \partial_t a"
// is the induced (eddy) current density, due to the time-varying magnetic
// flux. The total current density in a conducting region is thus "j = -sigma
// \partial_t a" (purely induced) and in a source region it is "j = js" (purely
// imposed). See the PostProcessing section below, which defines the full "j"
// piecewise on the two kinds of regions.
//
// We consider both time-domain (transient) and frequency-domain (steady-state)
// resolutions, with a sinusoidal source current density at fixed frequency f:
//
//   js(t) = (0, 0, Js sin(2 pi f t))
//
// As in tutorial 3, with a source current density along the z-axis, the
// magnetic vector potential a is a vector field with a single non-zero
// component along the z-axis, i.e.,
//
//   a(x, y, t) = (0, 0, az(x, y, t))
//
// and we can use the same "Form1P" function space with the same
// "BF_PerpendicularEdge" basis functions.
//
// In the time-domain an implicit Euler time stepping scheme is used, whereas in
// the frequency domain, we solve for the phasor "A(x, y)" such that
//
//   a(x, y, t) = Re( A(x, y) exp(i 2 pi f t) )
//
// Note that with this definition of phasors in terms of peak values, a factor
// 1/2 appears in time-averaged quadratic quantities such as electromagnetic
// power (due to the time-averaged cosine squared over a period). This factor
// disappears for phasors defined in terms of RMS values, or for the calculation
// of instantaneous power in the time-domain.

Include "electromagnet_common.pro";

Group {
  // Physical regions:
  Core = Region[ 1 ];
  Air = Region[ 2 ];
  AirInf = Region[ 3 ];
  CoilRight = Region[ 4 ];
  Bottom = Region[ 10 ];
  Left = Region[ 11 ];
  Inf = Region[ 12 ];

  // Abstract regions:
  //  - "Vol_Mag": full volume domain
  //  - "Vol_S_Mag": region with imposed current source js
  //  - "Vol_C_Mag": conducting regions with eddy currents
  //  - "Vol_Inf_Mag": region with infinite ring geometric transformation
  //  - "Sur_Neu_Mag": part of the boundary with non-homogeneous Neumann
  //    conditions
  Vol_Mag     = Region[ {Air, AirInf, Core, CoilRight} ];
  Vol_S_Mag   = Region[ CoilRight ];
  Vol_C_Mag   = Region[ Core ];
  Vol_Inf_Mag = Region[ AirInf ];
  Sur_Neu_Mag = Region[ {} ]; // empty
}

Function {
  DefineConstant[
    AnalysisType = {1, Choices{0="Time-domain", 1="Frequency-domain"},
      Name "Parameters/Analysis type"}
    // In addition to a 2D model (invariant along the z-axis) we also consider
    // an axisymmetric model (invariant by rotation around the y-axis). This is
    // appropriate when the 3D device is itself a solid of revolution -- as with
    // a cylindrical coil. It would not be appropriate for, e.g., a
    // rotating-machine cross-section, which is only piecewise-invariant by
    // rotation:
    Axisymmetric = {0, Choices{0, 1},
      Name "Parameters/Axisymmetric model?"}
    Current = {1, Min 0.01, Max 100, Step 0.1,
      Name "Parameters/Current [A]"}
    f = {5, Min 1, Max 1000, Step 1,
      Name "Parameters/Frequency [Hz]"}
    mur = {1000, Min 1, Max 5000, Step 1,
      Name "Parameters/Core relative permeability"}
    sigma = {1e6, Min 1, Max 1e6, Step 100,
      Name "Parameters/Core conductivity [S m^-1]"}
  ];

  T = 1 / f;
  dt = T / 20;
  tmax = 2 * T;

  mu0 = 4.e-7 * Pi;
  nu0 = 1 / mu0;
  nu [ Region[{Air, AirInf, CoilRight}] ] = nu0;
  nu [ Core ]  = 1 / (mur * mu0);

  sigma[ Core ] = sigma;

  SkinDepth = DefineNumber[ 1e3 * Sqrt[2 / (2 * Pi * f * mur * mu0 * sigma)],
    Name "Parameters/Skin depth [mm]", ReadOnly];

  NbTurns = 1000;

  // The built-in function "F_Sin_wt_p[]{2 * Pi * f, 0}" will be interpreted as
  // "Sin[2 * Pi * f * $Time]" in the time domain, where "$Time" denotes the
  // current value of time, and as "Complex[0, -1]" in the frequency domain.
  //
  // The syntax "Complex[Re, Im]" builds a complex number from its real and
  // imaginary parts: "Complex[0, 1]" is the imaginary unit "i", and "Complex[0,
  // -1] = -i" is the phasor of "sin(omega t)" under the convention "x(t) = Re[X
  // exp(i omega t)]" (indeed, "sin(omega t) = Re[-i exp(i omega t)]").
  js[ CoilRight ] = Vector[0, 0, -NbTurns * Current / (dxCoil * dyCoil)] *
    F_Sin_wt_p[]{2 * Pi * f, 0};

  // Coefficient for computing electromagnetic power: 1 for time-domain
  // (instantaneous) power or for RMS phasors, 1/2 for peak-valued phasors:
  CoefPower = (AnalysisType == 0) ? 1 : 0.5;
}

Constraint {
  { Name a_Mag_2D;
    Case {
      { Region Left; Value 0.; }
      { Region Inf; Value 0.; }
    }
  }
}

Group {
  Dom_Hcurl_a_Mag_2D = Region[ {Vol_Mag, Sur_Neu_Mag} ];
}

FunctionSpace {
  { Name Hcurl_a_Mag_2D; Type Form1P;
    BasisFunction {
      { Name se; NameOfCoef ae; Function BF_PerpendicularEdge;
        Support Dom_Hcurl_a_Mag_2D; Entity NodesOf[ All ]; }
    }
    Constraint {
      { NameOfCoef ae; EntityType NodesOf; NameOfConstraint a_Mag_2D; }
    }
  }
}

Jacobian {
  { Name Vol;
    Case {
      // Solving an axisymmetric problem in GetDP is achieved by specifying the
      // axisymmetric variants of the Jacobian transformations, i.e. replacing
      // "Vol" with "VolAxi" and "VolSphShell" with "VolAxiSphShell":
      If(Axisymmetric)
        { Region Vol_Inf_Mag; Jacobian VolAxiSphShell {rInt, rExt}; }
        { Region All; Jacobian VolAxi; }
        // The axisymmetric Jacobians assume that the domain is in the z == 0
        // plane, and that the rotation axis is the y-axis.
      Else
        { Region Vol_Inf_Mag; Jacobian VolSphShell {rInt, rExt}; }
        { Region All; Jacobian Vol; }
      EndIf
    }
  }
}

Integration {
  { Name Int;
    Case {
      { Type Gauss;
        Case {
          // With piecewise linear basis functions we must be able to integrate
          // quadratic polynomials in "Vol_C_Mag", hence we use 3 integration
          // points instead of 1 as in tutorial 3:
          { GeoElement Triangle; NumberOfPoints 3; }
        }
      }
    }
  }
}

// The weak formulation is derived in a similar way as for the magnetostatic
// problem from tutorial 3: find "a" such that
//
//   (curl(nu curl a), a')_Vol_Mag + (sigma \partial_t a, a')_Vol_C_Mag
//     = (js, a')_Vol_S_Mag
//
// holds for all test functions "a'". After integration by parts, and with the
// same boundary conditions as in tutorial 3, it reads: find a such that
//
//   (nu curl a, curl a')_Vol_Mag + (sigma \partial_t a, a')_Vol_C_Mag
//     = (js, a')_Vol_S_Mag
//
// holds for all test functions "a'".
Formulation {
  { Name Magnetoquasistatics_a_2D; Type FemEquation;
    Quantity {
      { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
    }
    Equation {
      Integral { [ nu[] * Dof{d a} , {d a} ];
        In Vol_Mag; Jacobian Vol; Integration Int; }

      Integral { DtDof [ sigma[] * Dof{a} , {a} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }

      Integral { [ - js[] , {a} ];
        In Vol_S_Mag; Jacobian Vol; Integration Int; }
    }
  }
}

Resolution {
  { Name Mag;
    System {
      { Name Sys_Mag; NameOfFormulation Magnetoquasistatics_a_2D;
        If(AnalysisType == 1)
          // With "Type Complex" and "Frequency f", GetDP transforms the "DtDof"
          // operator as a multiplication by "Complex[0, 2 * Pi * f]", and
          // handles all fields as complex-valued phasors:
          Type Complex; Frequency f;
        EndIf
      }
    }
    Operation {
      If(AnalysisType == 1)
        Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
      Else
        // If no "Init" constraint is given, "InitSolution[]" initializes the
        // solution to 0:
        InitSolution[Sys_Mag];
        TimeLoopTheta[0, tmax, dt, 1] {
          Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
        }
      EndIf
    }
  }
}

PostProcessing {
  { Name Mag; NameOfFormulation Magnetoquasistatics_a_2D;
    Quantity {
      { Name a;
        Value {
          Term { [ {a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name az; // z-component of the vector potential
        Value {
          Term { [ CompZ[{a}] ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name b;
        Value {
          Term { [ {d a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name h;
        Value {
          Term { [ nu[] * {d a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      // The current density can be defined piecewise: as the induced (eddy)
      // current density in the conducting regions, and as the source current
      // density in the inductor regions:
      { Name j;
        Value {
          Term { [ - sigma[] * Dt[{a}] ]; In Vol_C_Mag; Jacobian Vol; }
          Term { [ js[] ]; In Vol_S_Mag; Jacobian Vol; }
        }
      }
      // We can compute Joule losses by integrating "1 / sigma |j|^2" over the
      // domain (beware of time-averaging with phasors, cf. the definition of
      // "CoefPower" above), which can be done by defining an "Integral"
      // post-processing quantity, again piecewise. In the conducting regions
      // the current is induced, "j = -sigma \partial_t a", so "|j|^2 / sigma =
      // sigma |\partial_t a|^2". In the source regions the current is imposed,
      // and we keep "|js|^2 / sigma" directly:
      { Name JouleLosses;
        Value {
          Integral { [ CoefPower * sigma[] * SquNorm[Dt[{a}]] ];
            In Vol_C_Mag; Jacobian Vol; Integration Int; }
          Integral { [ CoefPower / sigma[] * SquNorm[js[]] ];
            In Vol_S_Mag; Jacobian Vol; Integration Int; }
        }
      }
    }
  }
}

PostOperation {
  { Name Map; NameOfPostProcessing Mag;
    Operation {
      // In the time domain, the output files will contain the values at each
      // time step. In the frequency domain, they will contain two values: the
      // real and imaginary parts.
      Print[ a, OnElementsOf Vol_Mag, File "a.pos" ];
      Print[ az, OnElementsOf Vol_Mag, File "az.pos" ];
      Print[ b, OnElementsOf Vol_Mag, File "b.pos" ];
      Print[ b, OnLine{{mm, mm, 0}{rInt, mm, 0}}{50}, File "cutb.pos" ];
      Print[ j, OnElementsOf Vol_S_Mag, File "js.pos" ];
      Print[ j, OnElementsOf Vol_C_Mag, File "j.pos" ];
      // Integral post-processing quantities do not make sense on elements on
      // the mesh, as they are global values. Here we evaluate the Joule losses
      // over the conducting regions:
      Print[ JouleLosses[Vol_C_Mag], OnGlobal, Format Table, File "losses.txt" ];
    }
  }
}
