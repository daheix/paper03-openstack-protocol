# GetDP Tutorial

The following tutorials provide a progressive introduction to GetDP. Each
tutorial builds on the previous ones, introducing new modelling concepts,
formulation techniques and solver features. They are designed to be studied in
order:

1. **Electrostatics**: Scalar potential formulation, Lagrange elements,
   Dirichlet boundary conditions.
2. **Thermal**: Heat equation with conduction and convection, Neumann and
   Robin boundary conditions, steady-state and transient analyses, periodic
   constraints.
3. **Magnetostatics**: Vector potential formulation, infinite elements,
   nonlinear materials with Newton-Raphson and Picard iterations.
4. **Magneto-quasistatics**: Eddy currents, frequency- and time-domain
   analyses, axisymmetric models.
5. **Full wave**: Edge elements, absorbing boundary conditions,
   Dirichlet constraint through an auxiliary resolution.
6. **Global quantities**: Global basis functions, floating potentials,
   electrode charges and capacitances.
7. **Coupled problems**: a-v formulation with global currents and voltages,
   magneto-thermal coupling, staggered resolution.
8. **Circuit coupling**: Lumped circuit elements, network constraints,
   Kirchhoff's laws, tree-cotree gauging in 3D.
9. **Template library**: Generic formulation library, transformer with
   magnetically coupled circuits, stranded coils, ferromagnetic laminations.
10. **Gauging**: Tree-cotree vs. Coulomb gauge, 3D transformer model with
   global coil basis functions.

Each [tutorial directory](https://gitlab.onelab.info/getdp/getdp/tree/master/tutorials/)
contains a `.geo` file (geometry and mesh), a `.pro` file (finite element model)
and a `README.md` with instructions. The `.pro` and `.geo` files are heavily
commented -- the comments are the tutorial.

All tutorials can be run interactively with Gmsh (open the `.pro` file, then
press "Run") or from the command line (see the `README.md` in each directory).

## Further reading

The tutorials cover a fair amount of the underlying mathematics of the finite
element method and of the physics of the problems they address, but they do not
aim to be a self-contained treatise on either. The following references are
useful companions, grouped from most directly relevant to the tutorials' main
topic to more general background.

- **J.-M. Jin**, *The Finite Element Method in Electromagnetics*, 3rd edition,
  Wiley-IEEE Press, 2014 (ISBN 978-1-118-57136-1).  Practitioner-oriented survey
  of the whole field; mirrors the tutorial progression.

- **G. Meunier (ed.)**, *The Finite Element Method for Electromagnetic
  Modeling*, Wiley-ISTE, 2008 (ISBN 978-1-84821-030-1). Low-frequency
  applications, circuit coupling, motion, magneto-thermal coupling; relevant to
  tutorials 1, 3, 4, 7, 8 and 9.

- **A. Bossavit**, *Computational Electromagnetism: Variational Formulations,
  Complementarity, Edge Elements*, Academic Press, 1998 (ISBN
  0-12-118710-1). Geometric / differential-forms view of electromagnetism;
  relevant to tutorials 3, 4, 5, 7 and 10.

- **P. Monk**, *Finite Element Methods for Maxwell's Equations*, Oxford
  University Press, 2003 (ISBN 0-19-850888-3). Mathematical reference for
  H(curl) elements and absorbing boundary conditions; relevant to tutorial 5.

- **D. Boffi, F. Brezzi, M. Fortin**, *Mixed Finite Element Methods and
  Applications*, Springer Series in Computational Mathematics vol. 44, Springer,
  2013 (ISBN 978-3-642-36518-8;
  [doi:10.1007/978-3-642-36519-5](https://doi.org/10.1007/978-3-642-36519-5)).
  Theory of mixed methods and the de Rham complex underlying tutorials 5, 6, 7
  and 10.

- **A. Ern, J.-L. Guermond**, *Theory and Practice of Finite Elements*, Applied
  Mathematical Sciences vol. 159, Springer, 2004 (ISBN 0-387-20574-8;
  [doi:10.1007/978-1-4757-4355-5](https://doi.org/10.1007/978-1-4757-4355-5)).
  General-purpose graduate FE textbook; useful companion for the underlying FE
  machinery.
