# GetDP tutorial 7: Magneto-thermal model of a three-phase busbar

We consider a coupled 2D magneto-thermal model of a three-phase busbar system with
insulation and a grounded metallic shield. The magnetic problem is solved with
an a-v formulation, with global currents and voltages defined on all the
conducting regions. The steady-state heat distribution due to the Joule losses
is computed, taking the temperature-dependency of electrical conductivity into
account.

## Features

 - Global currents and voltages in 2D a-v magneto-quasistatics
 - Magneto-thermal resolution with multiphysics coupling
 - Staggered resolution

See the comments in `busbar.pro` and `busbar.geo` for details.

## Running the tutorial

On the command line:
```
> gmsh busbar.geo -2
> getdp busbar.pro -solve MagThe -pos MapMag MapThe
```

Interactively with Gmsh: open `busbar.pro` with "File->Open", then press "Run".
