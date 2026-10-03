# Frozen Experiment Plan — Paper 3 (T2 protocolized gap)

Frozen 2026-10-03 (goal R8) **before any measurement**. Changes only via
commit + CHANGELOG.

## Model population

- Source library: `src/plugins/motor_workbench/models/library/` (1,690 files;
  1,621 valid per AGENTS.md 2026-10 calibration note; 69 excluded as invalid).
- Families: slot × pole matrix, 16 slot-families × 6 pole-counts, plus an
  eccentric fault family (ecc < air gap enforced).
- Solve chain: `run_emag_getdp.py --params --workdir` (Gmsh 4.15.2 meshing,
  GetDP 4.0.0 magnetostatics, P1), metrics: Bg1, THD, λm, torque, self-energies.

## Stratified sample (30)

- Strata = 16 slot-families; within stratum pick models spanning the pole
  range; oversample the eccentric family (3 models) for fault-relevant
  gradients: **27 regular + 3 eccentric**.
- Selection is deterministic: sort candidates by model id, take every
  ⌈N_stratum/allow⌉-th; seed 20261003 recorded; sampling script
  `scripts/sample_models.py` writes `data/sample30.json`.

## Ablation arms (each model, each metric of interest)

| Arm | Name | What runs | Output |
|---|---|---|---|
| A0 | bare | single default-mesh solve | metric value only |
| A1 | +mesh protocol | lc-air × {2.0, 1.0, 0.5} (3 levels) | 3 values + ratio table |
| A2 | +GCI | A1 + Richardson/GCI (3-point) | GCI%, observed order p, asymptotic flag |
| A3 | full protocol | A2 + Paper-2 arbitration (integral trio C1; ring band C2 where applicable) | verdict PASS/FAIL per metric |

- Mesh levels match the Paper-2 frozen sequence (lc_air 0.0020/0.001/0.0005
  for A1..A3 unless a model's default differs; default lc recorded per model).
- Wall time budget: ≤ 20 s/solve typical (2-core); per-model cap 300 s
  (timeout → record FAIL, never silently drop).

## Predictable-bound claim (to be tested, not assumed)

- H1: with A2, ≥ 90% of (model, metric) pairs reach the asymptotic regime
  (0.5 < p < 2.5 for P1) with GCI ≤ 5%.
- H2: full protocol A3 flags ≥ 95% of unreliable values (cross-checked
  against analytic anchors and Paper-2's eccentric family behaviour).
- Failure of H1/H2 is itself a publishable result (protocol boundary map).

## Analytic anchors (external, from Paper 2, same P1 kernel)

- A1 anchor: current-loaded disc, max err 0.917% (threshold 1%).
- A2 anchor: transversely magnetised cylinder, max err 0.66% (threshold 3%).
- Re-run at v0.2.0 to bind the anchor to this repo's environment.

## Threats to validity (pre-registered)

- No commercial-tool reference: claims are verification-grade (bounds, not
  truth); literature values used only as side evidence.
- Solver = one code path (P1); conclusions scoped to P1 linear magnetostatics.
- 30-model sample: family-level (not per-model) conclusions; stratification
  recorded to let readers reweight.

## Data release

`data/` receives per-arm CSVs (`results_arm{A0..A3}.csv`), the merged matrix
(`results_matrix.csv`), and `sample30.json`. Analysis scripts read CSVs only.
