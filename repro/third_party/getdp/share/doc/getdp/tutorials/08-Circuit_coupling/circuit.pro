// This tutorial shows how to couple a finite element model with a lumped
// element circuit. We consider two conductors (modelled with finite elements)
// connected in parallel and driven by a voltage source through a series
// resistance and inductance (modelled as lumped circuit elements). The circuit
// topology is described as follows (with circled numbers representing the
// circuit nodes):
//
//    (2)     +-----+   (3)   +-----+       (4)
//     +------+ R_1 +----+----+ L_1 +--------+------------+
//     |      +-----+         +-----+        |            |
//     |                                +----+----+  +----+----+
//  +--+--+                             |         |  |         |
//  | V_1 |                             | Cond_1  |  | Cond_2  |
//  +--+--+                             |         |  |         |
//     |                                +----+----+  +----+----+
//     |                                     |            |
//     +-------------------------------------+------------+
//    (1)
//
// The two conductors "Cond_1" and "Cond_2" are discretized with finite
// elements, while "V_1" (voltage source), "R_1" (resistance) and "L_1"
// (inductance) are lumped circuit elements.
//
// Both the 2D and the 3D cases are treated using an "a-v" magneto-quasistatic
// formulation in the conductors, which takes into account skin effect.
// Proximity effects are not modelled, as the magnetic problem is only solved in
// the conductors: there is no surrounding air region, so the two conductors are
// magnetically uncoupled.
//
// In 2D, the magnetic vector potential "a" is a perpendicular 1-form
// ("Form1P"), as in tutorials 4 and 7, and the electric scalar potential "v" is
// discretized with a single global degree of freedom per conducting region, as
// in tutorial 7. In 3D, "a" is a 1-form ("Form1") discretized with Whitney edge
// elements, as in tutorial 5. The electric scalar potential "v" is now a full
// scalar field inside each conductor, whose gradient is discretized with
// "BF_GradNode" (the gradient of the standard Lagrange basis functions) and
// "BF_GradGroupOfNodes" (the gradient of the global basis functions introduced
// in tutorial 6). An explicit gauge condition (tree-cotree gauging) is needed
// to remove the gradient fields from "a", which would otherwise be redundant
// with "grad v" (see below).
//
// Both frequency-domain and time-domain analyses are supported (as in tutorial
// 4).

Include "circuit_common.pro";

Group {
  // Physical regions (in the mesh):
  Cond_1 = Region[ 100 ];
  Cond_2 = Region[ 101 ];
  Bnd = Region[ 200 ];
  If(dim == 3)
    BotCond_1 = Region[ 300 ];
    TopCond_1 = Region[ 301 ];
    BotCond_2 = Region[ 302 ];
    TopCond_2 = Region[ 303 ];
  EndIf

  // Circuit regions. These are fictitious regions used to represent lumped
  // circuit elements. Their tags must not conflict with any physical group tag
  // in the mesh, so that GetDP can distinguish them from mesh-based regions:
  V_1 = Region[ 1000 ];
  R_1 = Region[ 1001 ];
  L_1 = Region[ 1002 ];

  // Abstract magnetic regions:
  //  - "Vol_Mag": full domain for the magnetic problem
  //  - "Vol_C_Mag": conducting regions
  //  - "Sur_Electrodes_Mag": electrode surfaces with voltages and currents in
  //    3D
  Vol_Mag = Region[ {Cond_1, Cond_2} ];
  Vol_C_Mag = Region[ {Cond_1, Cond_2} ];
  If(dim == 3)
    Sur_Electrodes_Mag = Region[ {BotCond_1, TopCond_1, BotCond_2, TopCond_2} ];
  EndIf

  // Abstract circuit regions. These groups allow a generic treatment of the
  // lumped element constitutive relations in the Formulation (see the
  // GlobalTerms below):
  //  - "Resistance_Cir": resistors (U = R I)
  //  - "Inductance_Cir": inductors (U = L dI/dt)
  //  - "Capacitance_Cir": capacitors (I = C dU/dt)
  //  - "Dom_Cir": all lumped circuit elements
  Resistance_Cir = Region[ {R_1} ];
  Inductance_Cir = Region[ {L_1} ];
  Capacitance_Cir = Region[ {} ]; // empty, but kept for completeness
  Dom_Cir = Region[ {V_1, R_1, L_1} ];
}

Function {
  DefineConstant[
    AnalysisType = {1, Choices{0="Time-domain", 1="Frequency-domain"},
      Name "Parameters/1Analysis type"}
    Voltage = {0.1, Min 1e-3, Max 10, Step 1,
      Name "Parameters/2Voltage source [V]"}
    // In the frequency domain we consider an AC voltage source with frequency
    // "f":
    f = {1000, Min 1, Max 10000, Step 10, Visible AnalysisType == 1,
      Name "Parameters/3Frequency [Hz]"}
    // In the time domain we consider a step voltage with given rise time "tr",
    // and run the simulation for "10 * tr":
    tr = {1e-3, Min 1e-5, Max 1, Step 1e-3, Visible AnalysisType == 0,
      Name "Parameters/3Rise time"}
    Rval = {10e-3, Min 0, Max 100, Step 0.1,
      Name "Parameters/4Series resistance [Ohm]"}
    Lval = {5e-6, Min 0, Max 100e-6, Step 1e-6,
      Name "Parameters/4Series inductance [H]"}
  ];

  If(AnalysisType == 1)
    tfct[] = F_Cos_wt_p[]{2 * Pi * f, 0};
  Else
    tmax = 10 * tr;
    dt = tr / 10;
    // A simple ramp function for the step voltage:
    tfct[] = ($Time < tr) ? $Time / tr : 1;
  EndIf

  // Magnetic parameters:
  mu0 = 4 * Pi * 1e-7;
  nu[] = 1. / mu0;
  sigma[ Cond_1 ] = 5.8e7;
  sigma[ Cond_2 ] = 5.8e7;

  If(dim == 2)
    // In 2D, "CoefGeo[]" represents the out-of-plane thickness (as in tutorial
    // 7):
    CoefGeo[] = thick;
  Else
    // In 3D the thickness is part of the geometrical model and the mesh, so
    // "CoefGeo[] = 1":
    CoefGeo[] = 1;
  EndIf

  // Circuit parameters: the "Resistance[]", "Inductance[]" and "Capacitance[]"
  // functions are piecewise constants defined on the circuit regions, used in
  // the lumped element GlobalTerms of the Formulation:
  Resistance[ R_1 ] = Rval;
  Inductance[ L_1 ] = Lval;
  Capacitance[ ] = 0; // unused
}

Constraint {
  // Homogeneous Dirichlet condition on the magnetic vector potential on the
  // outer boundaries:
  { Name a_Mag;
    Case {
      { Region Bnd; Value 0.; }
    }
  }

  // Tree-cotree gauge condition for the 3D vector potential (see the
  // FunctionSpace definition below for details):
  { Name a_Gauge_Mag;
    Case {
      { Region Vol_C_Mag ; SubRegion Bnd; Value 0.; }
    }
  }

  // No imposed current constraint on the FE conductors (the current will be
  // determined by the circuit):
  { Name Current_Mag;
    Case {
    }
  }

  { Name Voltage_Mag;
    Case {
      If(dim == 3)
        // In 3D, set the absolute voltage on the bottom electrode of "Cond_1"
        // to 0 as a reference:
        { Region BotCond_1; Value 0; }
      EndIf
    }
  }

  // Initial condition on the circuit inductor current (for the time-domain
  // analysis):
  { Name Current_Cir ;
    Case {
      { Region L_1; Type Init; Value 0.; }
    }
  }

  // Imposed voltage on the voltage source:
  { Name Voltage_Cir ;
    Case {
      { Region V_1; Value Voltage; TimeFunction tfct[]; }
    }
  }

  // The circuit topology is described as a constraint of type "Network". Each
  // entry specifies a circuit element (a "Region") and the two circuit nodes
  // ("Branch") it connects, defining a directed branch from the first node to
  // the second. The circuit node numbers (1, 2, 3, 4, ...) are arbitrary labels
  // that refer to the ASCII art diagram at the top of this file.
  //
  // The sign convention is the same for all elements (sources and loads alike):
  // for a branch "Branch {a, b}", the current "I" is positive from node "a" to
  // node "b", and the voltage "U" is the potential rise from "a" to "b", i.e.
  // "U = V(b) - V(a)". This uniform "source" (or "generator") convention
  // differs from the "passive sign convention" commonly used in circuit
  // textbooks, where the current through a load is defined as flowing into the
  // positive voltage terminal.
  //
  // The constitutive law of each element determines the relation between "U"
  // and "I". With the source convention:
  //   - Resistor: U + R I = 0 (voltage drops in the direction of current)
  //   - Inductor: U + L dI/dt = 0
  //   - Capacitor: I + C dU/dt = 0
  //   - Voltage source: U = Voltage * tfct[] (via the "Voltage_Cir" constraint)
  //
  // The power delivered by any element is "P = U I": sources have "P > 0" and
  // loads have "P < 0" (e.g. for a resistor, "P = U I = -R I^2 < 0").
  { Name ElectricalCircuit ; Type Network ;
    Case Circuit_1 {
      // Lumped elements:
      { Region V_1; Branch {1, 2}; }
      { Region R_1; Branch {2, 3}; }
      { Region L_1; Branch {3, 4}; }

      If(dim == 2)
        // In 2D, each conducting region has a single voltage drop and current
        // flowing through it (in the direction perpendicular to the plane). It
        // behaves as a two-terminal circuit element and can be directly
        // inserted between two circuit nodes. Here both conductors are
        // connected in parallel between nodes 4 and 1:
        { Region Cond_1; Branch {4, 1} ; }
        { Region Cond_2; Branch {4, 1} ; }
      Else
        // In 3D, each electrode surface carries a voltage (absolute potential)
        // and a current. To impose a voltage drop across a conductor (say
        // "Cond_1") in the circuit -- rather than an absolute voltage on each
        // electrode surface independently -- we use an "anti-serial"
        // connection.  The key idea is to connect the top and bottom electrodes
        // with opposite node orderings, so that their absolute voltages are
        // subtracted:
        //
        //   V_drop(Cond_1) = V(TopCond_1) - V(BotCond_1).
        //
        // This is achieved by connecting "TopCond_1" from node 4 to an
        // intermediate node 10, and "BotCond_1" from node 1 to the same node 10
        // (note the reversed direction). The voltage between nodes 4 and 1 then
        // corresponds to the voltage drop over "Cond_1", regardless of the
        // absolute voltage values. The current convention is also consistent:
        // the current flowing into "TopCond_1" equals the current flowing out
        // of "BotCond_1".
        //
        // Note: in this particular circuit, since "BotCond_1" is fixed at 0 V
        // through the "Voltage_Mag" constraint, the anti-serial connection for
        // the bottom face is not strictly necessary. However, it is included
        // here for generality. Beware that if the bottom face is removed from
        // the Network, the corresponding region "BotCond_1" has to be removed
        // from "Sur_Electrodes_Mag" as well!
        { Region TopCond_1; Branch {4, 10} ; }
        { Region BotCond_1; Branch {1, 10} ; }

        { Region TopCond_2; Branch {4, 11} ; }
        { Region BotCond_2; Branch {1, 11} ; }
      EndIf
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

FunctionSpace {
  If(dim == 2)
    // In 2D, the magnetic vector potential and the gradient of the electric
    // scalar potential are discretized as in tutorial 7:
    { Name Hcurl_a_Mag_2D; Type Form1P;
      BasisFunction {
        { Name se; NameOfCoef ae; Function BF_PerpendicularEdge;
          Support Vol_Mag; Entity NodesOf[All]; }
      }
      Constraint {
        { NameOfCoef ae; EntityType NodesOf; NameOfConstraint a_Mag; }
      }
    }
    { Name Hcurl_u_Mag_2D; Type Form1P;
      BasisFunction {
        { Name sr; NameOfCoef ur; Function BF_RegionZ;
          Support Vol_C_Mag; Entity Vol_C_Mag; }
      }
      GlobalQuantity {
        { Name Voltage; Type AliasOf; NameOfCoef ur; }
        { Name Current; Type AssociatedWith; NameOfCoef ur; }
      }
      Constraint {
        { NameOfCoef Voltage; EntityType Region; NameOfConstraint Voltage_Mag; }
        { NameOfCoef Current; EntityType Region; NameOfConstraint Current_Mag; }
      }
    }
  Else
    // In 3D, the magnetic vector potential is a true 1-form ("Form1"), as in
    // tutorial 5, discretized with Whitney edge basis functions "BF_Edge"
    // associated with the edges of the mesh:
    { Name Hcurl_a_Mag_3D; Type Form1;
      BasisFunction {
        { Name se; NameOfCoef ae; Function BF_Edge;
          Support Vol_Mag; Entity EdgesOf[All]; }
      }
      Constraint {
        { NameOfCoef ae; EntityType EdgesOf; NameOfConstraint a_Mag; }
        // Tree-cotree gauge condition for 3D. In the conducting regions, the
        // electric field "e = -\partial_t a - grad v" involves two unknowns,
        // "a" and "grad v", but only their sum matters physically. Since the
        // edge element space of "a" can represent arbitrary gradient fields,
        // any gradient could be moved freely between "a" and "grad v" without
        // changing "e": the system is thus singular without an additional
        // constraint.
        //
        // Tree-cotree gauging removes gradient fields from "a" by setting to
        // zero the degrees of freedom of "a" on the edges of a spanning tree of
        // the mesh graph in "Vol_C_Mag". The "EdgesOfTreeIn" entity type
        // selects such a tree, rooted on the boundary "Bnd" (specified by
        // "EntitySubType StartingOn") where "a" is already constrained to
        // zero. This action eliminates the irrotational (gradient) components
        // of "a", leaving only the solenoidal part; "ur" alone will carry the
        // gradient part of the electric field.
        //
        // See tutorial 10 for more details about gauging.
        { NameOfCoef ae; EntityType EdgesOfTreeIn; EntitySubType StartingOn;
          NameOfConstraint a_Gauge_Mag; }
      }
    }

    // In 3D, the electric scalar potential "v" is a full field (not just a
    // single DOF per region as in 2D). Its gradient "grad v" is discretized in
    // H(curl) with two types of basis functions:
    //  - "BF_GradNode": the gradient of the standard Lagrange (nodal) basis
    //    functions, associated with the interior nodes of each conductor
    //    (excluding the electrode surfaces). These capture the spatial
    //    variation of "v" inside the conductor.
    //  - "BF_GradGroupOfNodes": the gradient of the global basis functions
    //    associated with the electrode surfaces (as in tutorial 6 with
    //    "BF_GroupOfNodes", but here through the gradient). Each electrode
    //    carries a single global voltage and current.
    //
    // The resulting expansion of "grad v" in conductor "r" reads:
    //
    //   grad v(x,y,z) = Sum_k un_k grad(sn_k(x, y, z))
    //     + Sum_electrode ur_electrode grad(sr_electrode(x,y,z))
    //
    // where the first sum runs over interior nodes and the second over
    // electrode surfaces. Note that we could alternatively have defined the
    // scalar potential "v" directly (as a "Form0" with "BF_Node" and
    // "BF_GroupOfNodes"), but then the Formulation would need to be written
    // differently in 2D and 3D. By defining "grad v" directly as a "Form1",
    // the same Formulation can be shared between 2D and 3D (see below).
    { Name Hcurl_u_Mag_3D; Type Form1;
      BasisFunction {
        { Name sn; NameOfCoef un; Function BF_GradNode;
          Support Vol_C_Mag; Entity NodesOf[Vol_C_Mag, Not Sur_Electrodes_Mag]; }
        { Name sr; NameOfCoef ur; Function BF_GradGroupOfNodes;
          Support Vol_C_Mag; Entity GroupsOfNodesOf[Sur_Electrodes_Mag]; }
      }
      GlobalQuantity {
        { Name Voltage; Type AliasOf; NameOfCoef ur; }
        { Name Current; Type AssociatedWith; NameOfCoef ur; }
      }
      Constraint {
        { NameOfCoef Voltage; EntityType GroupsOfNodesOf;
          NameOfConstraint Voltage_Mag; }
        { NameOfCoef Current; EntityType GroupsOfNodesOf;
          NameOfConstraint Current_Mag; }
      }
    }
  EndIf

  // The circuit currents and voltages are discretized with a scalar ("Type
  // Scalar") function space using "BF_Region" basis functions. "BF_Region" is a
  // region-wise constant scalar function (equal to 1 in its associated region
  // and 0 elsewhere), which is the scalar counterpart of the vector
  // "BF_RegionZ" used in 2D. Each lumped circuit element carries one current
  // DoF and one voltage DoF (its energy dual):
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
  // The formulation combines the FE magneto-quasistatic a-v weak formulation (as
  // in tutorial 7) with the lumped element constitutive relations and the
  // circuit topology (Kirchhoff's laws). All these contributions are assembled
  // into a single linear system.
  { Name Magnetoquasistatics_av; Type FemEquation;
    Quantity {
      // FE degrees of freedom (2D or 3D):
      If(dim == 2)
        { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
        { Name ur; Type Local; NameOfSpace Hcurl_u_Mag_2D; }
        { Name I; Type Global; NameOfSpace Hcurl_u_Mag_2D [Current]; }
        { Name U; Type Global; NameOfSpace Hcurl_u_Mag_2D [Voltage]; }
      Else
        { Name a; Type Local; NameOfSpace Hcurl_a_Mag_3D; }
        { Name ur; Type Local; NameOfSpace Hcurl_u_Mag_3D; }
        { Name I; Type Global; NameOfSpace Hcurl_u_Mag_3D [Current]; }
        { Name U; Type Global; NameOfSpace Hcurl_u_Mag_3D [Voltage]; }
      EndIf

      // Circuit degrees of freedom:
      { Name Iz; Type Global; NameOfSpace Hregion_i_Cir [Current]; }
      { Name Uz; Type Global; NameOfSpace Hregion_i_Cir [Voltage]; }
    }
    Equation {
      // FE terms for the a-v formulation (as in tutorial 7):
      Integral { [ nu[] * Dof{d a} , {d a} ];
        In Vol_Mag; Jacobian Vol; Integration Int; }
      Integral { DtDof [ sigma[] * Dof{a} , {a} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }
      Integral { [ sigma[] * Dof{ur} / CoefGeo[] , {a} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }

      Integral { DtDof [ sigma[] * Dof{a} , {ur} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }
      Integral { [ sigma[] * Dof{ur} / CoefGeo[] , {ur} ];
        In Vol_C_Mag; Jacobian Vol; Integration Int; }

      // In 2D the global current-voltage relation is per conducting region; in
      // 3D it is per electrode surface:
      If(dim == 2)
        GlobalTerm { [ Dof{I} * Sign[CoefGeo[]] , {U} ]; In Vol_C_Mag; }
      Else
        GlobalTerm { [ Dof{I} * Sign[CoefGeo[]] , {U} ]; In Sur_Electrodes_Mag; }
      EndIf

      // Lumped element constitutive relations, expressed as GlobalTerms. For
      // each lumped element, we have two unknowns: the current "Iz" and its
      // energy dual, the voltage "Uz". Two equations are needed per element:
      // one is the constitutive relation (below), the other comes from
      // Kirchhoff's laws (enforced by the GlobalEquation).
      //
      // All constitutive relations use the source sign convention defined in the
      // "ElectricalCircuit" network constraint above:
      //
      // Resistor: Uz + R * Iz = 0
      GlobalTerm { [ Dof{Uz} , {Iz} ]; In Resistance_Cir; }
      GlobalTerm { [ Resistance[] * Dof{Iz} , {Iz} ]; In Resistance_Cir; }

      // Inductor: Uz + L * dIz/dt = 0
      GlobalTerm { [ Dof{Uz} , {Iz} ]; In Inductance_Cir; }
      GlobalTerm { DtDof [ Inductance[] * Dof{Iz} , {Iz} ]; In Inductance_Cir; }

      // Capacitor: Iz + C * dUz/dt = 0 (unused here, but included for
      // completeness)
      GlobalTerm { [ Dof{Iz} , {Iz} ]; In Capacitance_Cir; }
      GlobalTerm { DtDof [ Capacitance[] * Dof{Uz} , {Iz} ]; In Capacitance_Cir; }

      // The "GlobalEquation" block enforces Kirchhoff's current and voltage
      // laws ("KCL" and "KVL", respectively), as specified by the
      // "ElectricalCircuit" network constraint. It couples the FE global
      // quantities (I, U) with the circuit global quantities (Iz, Uz) through
      // Kirchhoff's laws at each circuit node.
      //
      // Each entry in the GlobalEquation has:
      //  - "Node {x}": the current variable contributing to KCL at each node
      //  - "Loop {x}": the voltage variable contributing to KVL around each
      //    loop
      //  - "Equation {x}": the variable whose constitutive equation has been
      //    written (in the GlobalTerms above)
      //  - "In ...": the region(s) where this entry applies
      GlobalEquation {
        Type Network; NameOfConstraint ElectricalCircuit;
        If(dim == 2)
          { Node {I};  Loop {U};  Equation {I};  In Vol_C_Mag; }
        Else
          { Node {I};  Loop {U};  Equation {I};  In Sur_Electrodes_Mag; }
        EndIf
        { Node {Iz}; Loop {Uz}; Equation {Uz}; In Dom_Cir; }
      }
    }
  }
}

Resolution {
  { Name Mag;
    System {
      { Name Sys_Mag; NameOfFormulation Magnetoquasistatics_av;
        If(AnalysisType == 1)
          Type Complex; Frequency f;
        EndIf
      }
    }
    Operation {
      InitSolution[Sys_Mag];
      If(AnalysisType == 1)
        Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
      Else
        TimeLoopTheta[0, tmax, dt, 1] {
          Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
        }
      EndIf
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
      { Name b;
        Value {
          Term { [ {d a} ]; In Vol_Mag; Jacobian Vol; }
        }
      }
      { Name j;
        Value {
          Term { [ -sigma[] * (Dt[{a}] + {ur} / CoefGeo[]) ];
            In Vol_C_Mag; Jacobian Vol; }
        }
      }
      // Global quantities can be evaluated both on FE regions and on circuit
      // regions, using piecewise definitions:
      { Name U;
        Value {
          If(dim == 2)
            Term { [ {U} ]; In Vol_C_Mag; }
          Else
            Term { [ {U} ]; In Sur_Electrodes_Mag; }
          EndIf
          Term { [ {Uz} ]; In Dom_Cir; }
        }
      }
      { Name I;
        Value {
          If(dim == 2)
            Term { [ {I} ]; In Vol_C_Mag; }
          Else
            Term { [ {I} ]; In Sur_Electrodes_Mag; }
          EndIf
          Term { [ {Iz} ]; In Dom_Cir; }
        }
      }
    }
  }
}

PostOperation {
  { Name Map; NameOfPostProcessing Mag;
    Operation {
      Print[ a, OnElementsOf Vol_Mag, File "a.pos" ];
      Print[ b, OnElementsOf Vol_Mag, File "b.pos" ];
      Print[ j, OnElementsOf Vol_C_Mag, File "j.pos" ];
      If(dim == 2)
        Print[ U, OnRegion Vol_C_Mag, File "U.txt", Format RegionTable ];
        Print[ I, OnRegion Vol_C_Mag, File "I.txt", Format RegionTable ];
      Else
        Print[ U, OnRegion Sur_Electrodes_Mag, File "U.txt", Format RegionTable ];
        Print[ I, OnRegion Sur_Electrodes_Mag, File "I.txt", Format RegionTable ];
      EndIf
      Print[ U, OnRegion Dom_Cir, File "Uz.txt", Format RegionTable ];
      Print[ I, OnRegion Dom_Cir, File "Iz.txt", Format RegionTable ];

      // "SendToServer" sends the value to the Gmsh graphical user interface for
      // display in the left panel. The "}" prefix in the server name places
      // these entries at the bottom of the parameter tree:
      Print[ U, OnRegion V_1, File "", Format Table,
        SendToServer "}Output/V (V_1) [V]" ];
      Print[ I, OnRegion V_1, File "", Format Table,
        SendToServer "}Output/I (V_1) [A]" ];
      Print[ U, OnRegion L_1, File "", Format Table,
        SendToServer "}Output/V (L_1) [V]" ];
      Print[ I, OnRegion L_1, File "", Format Table,
        SendToServer "}Output/I (L_1) [A]" ];
    }
  }
}
