# Gap Evidence — Paper 3

## The gap (S2)

Open-source FE stacks (Gmsh/GetDP, FEMM, Elmer) are widely used for
electrical-machine analysis, but published practice offers no *protocol* that
turns a bare solve into a verifiable accuracy statement. The nearest prior
work is a single 2020 study coupling Gmsh/GetDP for induction-machine torque
optimisation (doi:10.1002/2050-7038.12773 field-stack lineage), which
optimises automatically without addressing accuracy bounds; standard
references describe the tools themselves (Geuzaine & Remacle 2009,
doi:10.1002/nme.2579) without a machine-metric accuracy protocol.

Grid convergence practice exists in CFD (Roache 1997, doi:10.1146/annurev.
fluid.29.1.123) but is rarely applied end-to-end to machine EM metrics, and
never combined with formulation arbitration (Paper 2, this series) and
analytic anchors into one workflow.

## Contribution claim (S1, testable)

A frozen 4-arm protocol (mesh sequence → GCI → arbitration) evaluated on a
stratified 30-model sample from a 1,690-model calibrated library, reporting:
GCI/order distributions per arm, the fraction of values entering the
asymptotic regime (H1), and the protocol's power to flag unreliable values
(H2). Positive or negative, the result maps the *engineering accuracy
boundary* of a representative open-source stack — currently absent from the
literature.

## Asset match (S3)

- 1,690-model library with frozen params + ≤1% calibration re-run record
  (project AGENTS.md 2026-10).
- Deterministic 2-core solve chain with progress hooks; Paper 2's frozen
  mesh-sequence driver + GCI analyzer + referee criterion (v0.3.0) reusable
  as-is.
- Analytic ladder (0.92%/0.66% anchors) from Paper 2 shares the P1 kernel.

## Metric (S4)

GCI %, observed order p, asymptotic flag, arbitration verdicts, wall time —
all machine-checkable from released CSVs.
