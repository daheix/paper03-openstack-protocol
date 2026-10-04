#!/usr/bin/env python3
"""L2 verify driver (protocol rule 12): re-run one locked reference case and
compare against repro/expected_results within 1%.

Reference case: g2-6s2p-rd (sample30_v3 sample_regular[0]), arm A0 (bare,
default lc_air=5e-4). Mirrors scripts/run_ablation.solve() exactly:
params.json -> run_emag_getdp.py --params --workdir (cwd = engine getdp dir).

Exit codes: 0 = all metrics within tolerance (PASS), 1 = any deviation >1%
or the solve itself failed.
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GETDP = REPO / "engine" / "simulation" / "getdp"
REF = REPO / "repro" / "expected_results" / "g2-6s2p-rd_A0_reference.json"
SAMPLE = REPO / "data" / "sample30_v3.json"
LIB = REPO / "repro" / "model_library"
WD = REPO / "data" / "verify" / "g2-6s2p-rd_A0"

METRIC_PATHS = {
    "no_load.r_sample": ("no_load", "r_sample"),
    "no_load.Bg_pole_mean": ("no_load", "Bg_pole_mean"),
    "no_load.Bg1": ("no_load", "Bg1"),
    "no_load.THD_pct": ("no_load", "THD_pct"),
    "no_load.Bg1_analytic_flat": ("no_load", "Bg1_analytic_flat"),
    "no_load.err_vs_analytic_pct": ("no_load", "err_vs_analytic_pct"),
}


def dig(report: dict, path: tuple[str, str]):
    node = report
    for key in path:
        node = node.get(key) if isinstance(node, dict) else None
        if node is None:
            return None
    return node


def main() -> int:
    ref = json.loads(REF.read_text())
    model_id = ref["model_id"]
    tol = ref["tolerance_pct"] / 100.0

    sample = json.loads(SAMPLE.read_text())
    if model_id not in sample["sample_regular"]:
        print(f"FAIL {model_id} not in {SAMPLE.name} sample_regular")
        return 1
    mf = LIB / f"{model_id}.json"
    if not mf.exists():
        print(f"FAIL library file missing: {mf}")
        return 1

    params = dict(json.loads(mf.read_text())["design"])
    WD.mkdir(parents=True, exist_ok=True)
    pf = WD / "params.json"
    pf.write_text(json.dumps(params))

    t0 = time.time()
    cmd = [sys.executable, "run_emag_getdp.py", "--params", str(pf),
           "--workdir", str(WD)]
    try:
        subprocess.run(cmd, cwd=GETDP, check=True, capture_output=True,
                       timeout=900)
    except subprocess.TimeoutExpired:
        print("FAIL solve timed out (900 s)")
        return 1
    except subprocess.CalledProcessError as e:
        log = (e.stderr or b"")[-500:].decode(errors="replace")
        print(f"FAIL solve crashed rc={e.returncode}\n{log}")
        return 1
    wall = time.time() - t0

    rpt = WD / "emag_report.json"
    if not rpt.exists():
        print("FAIL emag_report.json not produced")
        return 1
    report = json.loads(rpt.read_text())

    print(f"reference case : {model_id} / {ref['arm']} "
          f"(tolerance {tol:.1%}, wall {wall:.1f} s)")
    print(f"{'metric':<32}{'reference':>14}{'rerun':>14}{'dev':>10}")
    ok = True
    for name, path in METRIC_PATHS.items():
        want = ref["reference_metrics"].get(name)
        got = dig(report, path)
        if not isinstance(want, (int, float)) or not isinstance(
                got, (int, float)):
            print(f"{name:<32}{str(want):>14}{str(got):>14}{'  ?':>10}")
            ok = False
            continue
        dev = abs(got - want) / abs(want) if want else float("nan")
        mark = "PASS" if dev <= tol else "FAIL"
        if dev > tol:
            ok = False
        print(f"{name:<32}{want:>14.4f}{got:>14.4f}{dev:>9.2%} {mark}")
    print("VERIFY PASS" if ok else "VERIFY FAIL (>1% deviation or missing)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
