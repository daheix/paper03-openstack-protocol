# GetDP tutorial 9: Transformer model using a template library

We consider a 2D frequency-domain magneto-quasistatic model of a single-phase
transformer. The primary winding is driven by a voltage source and the secondary
winding feeds a selectable load (resistance, inductance or capacitance). Rather
than building the formulation from scratch as in previous tutorials, we use a
generic template library that provides the a-v formulation, function spaces,
resolution and post-processing.

## Features

 - Two electrically independent, magnetically coupled circuits
 - Stranded coils with number of turns, cross-section area and go/return sides
 - Homogenized laminated ferromagnetic core
 - Use of a generic template formulation library

See the comments in `transfo.pro` and `transfo.geo` for details.

## Running the tutorial

On the command line:
```
> gmsh transfo.geo -2
> getdp transfo.pro -solve Mag -pos Map
```

Interactively with Gmsh: open `transfo.pro` with "File->Open", then press "Run".

## Bonus

The [bonus tutorial](bonus/) reimplements the electromagnet models of tutorials
3 and 4 with the same template library, which makes static, time-domain and
frequency-domain analyses -- with or without axisymmetry -- available from a
single compact model file.
