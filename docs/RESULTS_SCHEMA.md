# Released data schema — `data/results/`

Every CSV is written by `scripts/run_ablation.py` (per-solve rows) and
`scripts/analyze_ablation.py` (gate table). One row per solve / per
(model, metric) pair. No numbers are hand-edited; regenerate everything
with `bash` steps in README.

## `<model_id>_arms.csv` — one row per solve

| column | meaning |
|---|---|
| `model` | model id (library filename stem) |
| `arm` | A0 bare / A1 mesh protocol |
| `mesh` | `default` (A0) or `coarse`/`mid`/`fine` (lc × 2.0 / 1.0 / 0.5) |
| `lc_scale` | mesh scale factor applied to lc_air/lc_iron/lc_shaft |
| `Bg1` | fundamental air-gap flux density [T] (radial, first harmonic) |
| `THD_pct` | air-gap flux-density THD [%] |
| `lambda_m_Wb` | magnet flux linkage λm [Wb] (energy method) |
| `T_avg_slope_Nm` | mean torque from W′(δ) slope ladder [Nm] |
| `T_avg_amp_Nm` | mean torque from co-energy swing amplitude [Nm] |
| `lambda1_energy_Wb` | λ₁ from the energy post-processor [Wb] |
| `runtime_s` | engine-reported solve time [s] |
| `wall_s` | driver-measured wall time [s] |
| `FAIL` | 1 = solve timed out (300 s) or engine crashed; metrics empty |

## `<model_id>_gci.csv` — one row per (model, metric)

| column | meaning |
|---|---|
| `metric` | one of the arms metrics, or `C1_slope_vs_amp` (arbitration) |
| `fine` / `mid` / `coarse` | the three A1 mesh-sequence values |
| `p_order` | observed convergence order from three-grid Richardson |
| `f_extrap` | Richardson-extrapolated value (fine-based) |
| `GCI_fine_pct` | grid convergence index on the fine mesh [%], factor 1.25 |
| `C1_pass` | arbitration only: 1 if \|slope−amp\|/slope ≤ 1.5% (Paper 2 C1) |

## `summary.csv` — gate table (one row per model × metric)

`p_order`, `GCI_fine_pct` plus the preregistered gate flags:
`in_range` (0.5 < p < 2.5), `gci_ok` (GCI ≤ 5%), `h1_pass` = both.
H1 counts the `h1_pass` share over all rated pairs; H2 reports the
flagged complement as the protocol's unreliable-value flag rate.

## Provenance chain

`data/sample30.json` (frozen sampler output, seed 20261003) →
`data/workdirs/<model>/<arm>/` (per-solve engine reports, git-ignored —
regenerable) → `data/results/*.csv` (released). Engine snapshot:
`engine/` + `docs/engine_snapshot.md` (SHA-256 manifest against upstream
commit). Frozen plan: `docs/experiment_plan.md` (preregisters H1/H2).
