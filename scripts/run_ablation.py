#!/usr/bin/env python3
"""4-arm ablation driver for Paper 3 (frozen plan docs/experiment_plan.md).

Per model:
  A0 bare        : default mesh (lc_air=5e-4), single solve.
  A1 mesh prot.  : lc scale {2.0, 1.0, 0.5} -> coarse/mid/fine solves.
  A2 +GCI        : Richardson extrapolation + GCI per metric on A1 solves.
  A3 full        : A1/A2 + formulation arbitration (Paper 2 C1 criterion,
                   analytic co-energy/flux ladder vs FE).

Writes data/results/<model>_arms.csv (one row per solve, arm-tagged) and
data/results/<model>_gci.csv (per-metric GCI). Any solve over --timeout s is
recorded as FAIL and does not silently drop the model.

Run inside engine/simulation/getdp so vendored imports resolve:
    python3 scripts/run_ablation.py --model baseline-12s4p
    python3 scripts/run_ablation.py --all --parallel 2
"""
import argparse
import csv
import json
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent                 # paper03/scripts
REPO = HERE.parent                                     # paper03/
GETDP = REPO / "engine" / "simulation" / "getdp"
RESULTS = REPO / "data" / "results"

LC_SCALES = {"coarse": 2.0, "mid": 1.0, "fine": 0.5}
METRICS = ["Bg1", "THD_pct", "T_avg_slope_Nm", "T_avg_amp_Nm",
           "lambda_m_Wb", "lambda1_energy_Wb"]

G_CGI = 1.25  # GCI fine safety factor (Roache 1994, 3-grid)


def solve(params: dict, wd: Path, timeout: int) -> dict | None:
    wd.mkdir(parents=True, exist_ok=True)
    if (wd / "emag_report.json").exists():   # resume: arm already solved
        return _read_report(wd / "emag_report.json")
    pf = wd / "params.json"
    pf.write_text(json.dumps(params))
    cmd = [sys.executable, "run_emag_getdp.py", "--params", str(pf),
           "--workdir", str(wd)]
    try:
        subprocess.run(cmd, cwd=GETDP, check=True, capture_output=True,
                       timeout=timeout)
    except subprocess.TimeoutExpired:
        return None
    return _read_report(wd / "emag_report.json")


def _read_report(rpt: Path) -> dict | None:
    """Parse emag_report.json -> ablation metric dict (None if missing)."""
    if not rpt.exists():
        return None
    r = json.loads(rpt.read_text())
    out = {}
    nl = r.get("no_load", {})
    out["Bg1"] = nl.get("Bg1")
    out["THD_pct"] = nl.get("THD_pct")
    fl = r.get("flux_linkage", {})
    out["lambda_m_Wb"] = fl.get("lambda_m_Wb")
    ts = r.get("torque_sweep", {})
    out["T_avg_slope_Nm"] = ts.get("T_avg_slope_Nm")
    out["T_avg_amp_Nm"] = ts.get("T_avg_amp_Nm")
    out["lambda1_energy_Wb"] = ts.get("lambda1_energy_Wb")
    out["runtime_s"] = r.get("runtime_s")
    return out


def gci3(f1: float, f2: float, f3: float, r: float = 2.0):
    """Three-grid Richardson: f1=fine, f2=mid, f3=coarse (h ratio r)."""
    eps = (f2 - f1) / (f3 - f2) if abs(f3 - f2) > 1e-15 else float("nan")
    p = 0.0 if abs(f3 - f2) < 1e-15 or abs(f2 - f1) < 1e-15 else (
        abs(__import__("math").log(abs(eps))) / __import__("math").log(r))
    if f2 == f1:
        return p, float("nan"), float("nan")
    fe = f1 + (f1 - f2) / (r**p - 1) if p > 0 and abs(r**p - 1) > 1e-12 else f1
    ga = abs((f2 - f1) / f1) if f1 else float("nan")
    return p, fe, G_CGI * ga


def arms_for(model: dict, model_id: str, timeout: int, wd_root: Path):
    d = dict(model["design"])
    rows, gci_rows = [], []

    # A0 bare
    t0 = time.time()
    a0 = solve(d, wd_root / model_id / "A0", timeout)
    if a0:
        a0.update({"model": model_id, "arm": "A0", "mesh": "default"})
        rows.append(a0)
    else:
        rows.append({"model": model_id, "arm": "A0", "mesh": "default",
                     "FAIL": 1, "wall_s": round(time.time() - t0, 1)})

    # A1 mesh protocol (3 solves)
    sols = {}
    for tag, s in LC_SCALES.items():
        p = dict(d)
        p["lc_air"], p["lc_iron"], p["lc_shaft"] = (
            d.get("lc_air", 5e-4) * s, d.get("lc_iron", 1.2e-3) * s,
            d.get("lc_shaft", 2e-3) * s)
        t0 = time.time()
        r = solve(p, wd_root / model_id / f"A1_{tag}", timeout)
        if r:
            r.update({"model": model_id, "arm": "A1", "mesh": tag,
                      "lc_scale": s})
            rows.append(r)
            sols[tag] = r
        else:
            rows.append({"model": model_id, "arm": "A1", "mesh": tag,
                         "lc_scale": s, "FAIL": 1,
                         "wall_s": round(time.time() - t0, 1)})
    # A2 GCI on fine/mid/coarse
    for m in METRICS:
        v = [sols[t].get(m) for t in ("fine", "mid", "coarse")]
        if all(isinstance(x, (int, float)) for x in v):
            p, fe, g = gci3(*v)
            gci_rows.append({"model": model_id, "metric": m,
                             "fine": v[0], "mid": v[1], "coarse": v[2],
                             "p_order": round(p, 3),
                             "f_extrap": fe, "GCI_fine_pct": (
                                 round(100 * g, 3) if g == g else "")})
    # A3 arbitration (Paper 2 C1): co-energy amplitude vs slope vs formula
    if {"fine", "mid", "coarse"} <= sols.keys():
        f = sols["fine"]
        ts_, tb = f.get("T_avg_slope_Nm"), f.get("T_avg_amp_Nm")
        if isinstance(ts_, (int, float)) and isinstance(tb, (int, float)) and ts_:
            rel = abs(tb / ts_ - 1)
            gci_rows.append({"model": model_id, "metric": "C1_slope_vs_amp",
                             "fine": tb, "mid": ts_, "coarse": "",
                             "p_order": "", "f_extrap": "",
                             "GCI_fine_pct": round(100 * rel, 3),
                             "C1_pass": int(rel <= 0.015)})
    return rows, gci_rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", help="single model_id from sample30.json")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--sample", default=str(REPO / "data" / "sample30.json"))
    ap.add_argument("--lib",
                    default="/home/wsc/wsc/ChinaSimStdio/src/plugins/"
                            "motor_workbench/models/library",
                    help="model library dir (dev machine path; override on "
                         "other hosts)")
    ap.add_argument("--timeout", type=int, default=300)
    ap.add_argument("--parallel", type=int, default=1)
    a = ap.parse_args()
    lib = Path(a.lib)
    sample = json.loads(Path(a.sample).read_text())
    ids = ([a.model] if a.model else
           sample["sample_regular"] + sample["sample_eccentric"])
    RESULTS.mkdir(parents=True, exist_ok=True)
    (RESULTS.parent / "workdirs").mkdir(exist_ok=True)
    for mid in ids:
        mf = lib / f"{mid}.json"
        if not mf.exists():
            print(f"SKIP {mid}: not in library")
            continue
        model = json.loads(mf.read_text())
        t0 = time.time()
        rows, gci = arms_for(model, mid, a.timeout,
                             RESULTS.parent / "workdirs")
        for name, data, hdr in (("arms", rows, None), ("gci", gci, None)):
            fp = RESULTS / f"{mid}_{name}.csv"
            if data:
                keys = list(data[0].keys())
                with open(fp, "w", newline="") as f:
                    w = csv.DictWriter(f, keys)
                    w.writeheader()
                    w.writerows(data)
        ok = sum(1 for r in rows if not r.get("FAIL"))
        print(f"{mid}: {ok}/{len(rows)} solves OK, {len(gci)} GCI rows, "
              f"{time.time()-t0:.0f}s -> {RESULTS}")


if __name__ == "__main__":
    main()
