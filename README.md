# paper03-openstack-protocol

**Series · Paper 3** — Engineering accuracy boundaries of an open-source
electromagnetic simulation stack via a *protocolized gap*: mesh protocol +
grid convergence index (GCI) + formulation arbitration + analytic anchors.

Series index: [daheix/daheix](https://github.com/daheix/daheix)
· Paper 1: EMSE-D-26-01301 (under review)
· Paper 2: [paper02-torque-arbitration](https://github.com/daheix/paper02-torque-arbitration)

## Research question

Can a *protocol* (mesh sequence + GCI + formulation arbitration + analytic
anchors) compress the accuracy of an open-source FE stack (Gmsh 4.15.2 +
GetDP 4.0.0, P1 magnetostatics) for electrical-machine metrics into a
*predictable bound*, and how much does each protocol component contribute?

## Design (frozen before any measurement — see docs/experiment_plan.md)

- **30 models**, stratified sample from a 1,690-model calibrated parameter
  library (16 slot-family × 6 pole-count families, incl. eccentric fault
  family), 2 cores, deterministic solves.
- **4 ablation arms**: bare run → +mesh protocol → +GCI → full protocol
  (+ formulation arbitration from Paper 2).
- **Metrics**: GCI %, observed convergence order p, arbitration verdicts,
  wall time. Error *bounds* (not "truth" claims) — verification methodology,
  analytic ladder as external anchor.

## Status

- [x] v0.1.0 — repo skeleton, frozen experiment plan, gap evidence
- [x] v0.1.1 — stratified sample (sample30.json)
- [ ] v0.2.0 — ablation driver + first data
- [ ] v0.3.0 — full 30×4 matrix + analysis
- [ ] manuscript (IET-style → target: Advances in Engineering Software)

## Reproduction environment (self-contained engine snapshot)

The FE engine is **vendored** in `engine/` (snapshot of the in-house stack at
upstream commit `35ddd14e1`, one patch: `lc_air/lc_iron/lc_shaft` exposed as
design parameters — see `docs/engine_snapshot.md` for the file manifest with
SHA-256). No installation of the upstream project is needed.

- **External tools**: Gmsh 4.15.2 (`gmsh -2 -format msh2`), GetDP 4.0.0
  (`getdp motor_mag.pro`), both on `PATH`; Python ≥ 3.10 + NumPy only.
- **One-shot**: `bash scripts/run_ablation.sh <model_id>` — runs all four
  arms for one model, writes `data/results/<model_id>_arms.csv`.
- **Full matrix** (30 models × 4 arms): `bash scripts/run_ablation.sh --all`
  (~2 h on 2 cores); aggregate with `python3 scripts/analyze_ablation.py`.
- Engine provenance: `docs/engine_snapshot.md`.

## License / citation

Code and data: see CITATION.cff. Values change only via tagged releases +
CHANGELOG.
