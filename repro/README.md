# P03 Reproducible Package (L2)

Locked, self-contained environment for **paper03_protocol** — the four-arm
mesh-protocol ablation over the stratified 30-model sample
(`data/sample30_v3.json`, `v3-amendment-3`, seed 20261003).

Per protocol rule 11 this package is independent of every other paper and of
the host project: solvers are bundled, Python deps are pinned exactly, and one
reference case defines the acceptance gate.

## Contents

| path | role |
|---|---|
| `Dockerfile` | `python:3.12.3-slim-bookworm` base, version-pinned; digest to be filled after first pull (see TODO) |
| `requirements.lock` | exact pins from `pip freeze` in a clean venv (11 packages, no floating ranges) |
| `third_party/gmsh`, `third_party/getdp` | bundled solver binaries (self-contained; only system dep is `libblas.so.3`) |
| `model_library/` | the 30 sample model definitions (16.6 KiB) copied from the frozen library |
| `expected_results/g2-6s2p-rd_A0_reference.json` | reference metrics + sha256 + 1% tolerance |
| `Makefile` | `make build` / `make run` / `make verify` |

Python layer: numpy 2.5.3, matplotlib 3.11.2 (only two third-party imports in
the executed chain; the rest of `requirements.lock` is their dependency
closure). Engine chain itself is numpy + stdlib only.

## Quick start

```bash
make build     # docker build -f repro/Dockerfile -t p03-repro:locked .
make run       # locked reference solve, results in repro/verify_out/
make verify    # rerun + compare against expected_results (<=1% = PASS)
```

`verify` re-runs case **g2-6s2p-rd / A0** (bare arm, default `lc_air=5e-4`)
via `scripts/verify_repro.py` and checks six no-load metrics
(`r_sample`, `Bg_pole_mean`, `Bg1`, `THD_pct`, `Bg1_analytic_flat`,
`err_vs_analytic_pct`). Reference values come from the protocol run of
2026-10-04; the reference `emag_report.json` sha256 is recorded alongside.

Baseline check on the dev host (same OS, no container): **VERIFY PASS, 6/6
metrics at 0.00% deviation** (`/tmp/p03_verify.log`, wall 112 s).

## L1 fallback (no Docker)

Python 3.12.x, then:

```bash
pip install -r repro/requirements.lock   # exact pins only
apt install libblas3 make                # getdp runtime dep
# solvers already bundled under repro/third_party/
python3 scripts/verify_repro.py
```

## Running the full ablation (A0–A3)

```bash
python3 scripts/run_ablation.py --all --sample data/sample30_v3.json \
    --lib repro/model_library
python3 scripts/analyze_ablation.py
```

Note `run_ablation.py` defaults `--lib` to the dev-machine absolute path;
inside the container (or any other host) pass `--lib repro/model_library`
as shown. Fine-arm solves have a 300 s per-solve timeout; timeouts are
recorded as FAIL rows (that is the measurable protocol boundary this paper
reports, not an error of the package).

## Honest status / TODO

- **Base-image digest**: no container runtime exists in the package-creation
  environment (checked: docker/podman/nerdctl/apptainer all absent), so the
  `python:3.12.3-slim-bookworm` digest is not yet pinned. On a docker host:
  `docker pull python:3.12.3-slim-bookworm && docker images --digests` and
  set `FROM python:3.12.3-slim-bookworm@sha256:<digest>`. Required before the
  protocol-rule-13 clean-environment acceptance run.
- **L3**: on reviewer request the built image goes to Zenodo with a DOI; the
  image itself is intentionally not committed to git.
