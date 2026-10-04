# GetDP tutorial 8: Circuit coupling in 2D and 3D

Two conductors modelled with finite elements are connected in parallel and driven
by a voltage source through a series resistance and inductance. The lumped
circuit elements and the finite element conductors are coupled through a network
constraint that enforces Kirchhoff's laws via a global equation. In 3D, the
vector potential is discretized with Whitney edge elements and a tree-cotree
gauge ensures uniqueness. Both frequency-domain and time-domain analyses are
supported.

## Features

 - Circuit coupling in 2D and 3D a-v magneto-quasistatics
 - Lumped resistors, inductors and voltage sources
 - Discretization of the 3D vector potential with tree-cotree gauging
 - Gradient basis functions for the 3D electric scalar potential

See the comments in `circuit.pro` and `circuit.geo` for details.

## Running the tutorial

On the command line (2D analysis):
```
> gmsh circuit.geo -2
> getdp circuit.pro -solve Mag -pos Map
```

On the command line (3D analysis):
```
> gmsh circuit.geo -3 -setnumber dim 3
> getdp circuit.pro -solve Mag -pos Map -setnumber dim 3
```

Interactively with Gmsh: open `circuit.pro` with "File->Open", then press "Run".
