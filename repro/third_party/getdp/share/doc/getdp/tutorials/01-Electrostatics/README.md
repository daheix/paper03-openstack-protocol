# GetDP tutorial 1: Electrostatic field around a microstrip line

A 2D electrostatic model of a microstrip line is considered, with only one half
of the geometry modelled by symmetry. A 1mV voltage is imposed on the microstrip
line, which sits on top of a dielectric substrate grounded on its lower side.

## Features

 - Electrostatic model in terms of the electric scalar potential
 - Physical and abstract regions
 - Scalar function space with Lagrange elements and Dirichlet constraint

See the comments in `microstrip.pro` and `microstrip.geo` for details.

## Running the tutorial

To run the tutorial on the command line:
```
> gmsh microstrip.geo -2
> getdp microstrip.pro -solve Ele -pos Map
```

To run the tutorial interactively with Gmsh: open `microstrip.pro` with
"File->Open", then press "Run".
