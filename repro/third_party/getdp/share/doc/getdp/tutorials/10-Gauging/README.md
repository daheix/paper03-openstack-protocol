# GetDP tutorial 10: Tree-cotree and Coulomb gauging

We consider a 3D version of the single-phase transformer of
[tutorial 9](../09-Template_library/). The primary winding is driven by a
voltage source and the secondary winding feeds a selectable load (resistance,
inductance or capacitance). In 3D, the curl-curl equation does not uniquely
determine the magnetic vector potential "a": gradient fields must be removed by
imposing a gauge condition. Two strategies are presented and can be selected at
runtime: tree-cotree gauging (which constrains the degrees of freedom on a
spanning tree of the mesh), as in [tutorial 8](../08-Circuit_coupling/), and
Coulomb gauging (which enforces "div a = 0" weakly via a scalar Lagrange
multiplier). Both produce the same magnetic flux density "b = curl a".

## Features

 - 3D magneto-quasistatic formulation with circuit coupling
 - Tree-cotree gauging via EdgesOfTreeIn / StartingOn
 - Coulomb gauging via a mixed formulation with Lagrange multiplier
 - Source current density obtained from an electrokinetic problem pre-computed
   on each coil

See the comments in `transfo.pro` and `transfo.geo` for details.

## Running the tutorial

On the command line:
```
> gmsh transfo.geo -3
> getdp transfo.pro -solve Mag -pos Map
```

Interactively with Gmsh: open `transfo.pro` with "File->Open", then press "Run".
