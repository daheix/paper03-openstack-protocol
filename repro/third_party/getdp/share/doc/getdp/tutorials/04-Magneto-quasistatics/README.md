# GetDP tutorial 4: Magneto-quasistatic model of an electromagnet

We consider the same electromagnet model as in
[tutorial 3](../03-Magnetostatics/), but in magneto-quasistatic regime, i.e.
allowing for time-dependent currents in the inductor and eddy currents in the
core. We still consider an imposed current density in the inductor, neglecting
skin and proximity effects in the coil turns. In addition to the 2D model
(invariant along the z-axis) we also consider an axisymmetric model (invariant
by rotation around the y-axis).

## Features

 - Magneto-quasistatic model in terms of the magnetic vector potential
 - Axisymmetric model
 - Time- and frequency-domain resolutions
 - Post-processing of integral quantities

See the comments in `electromagnet.pro` and `electromagnet.geo` for details.

## Running the tutorial

On the command line:
```
> gmsh electromagnet.geo -2
> getdp electromagnet.pro -solve Mag -pos Map
```

Interactively with Gmsh: open `electromagnet.pro` with "File->Open", then press
"Run".
