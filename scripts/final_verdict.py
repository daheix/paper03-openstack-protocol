#!/usr/bin/env python3
"""Final 30-sample verdict (Paper 3) — supersedes the mixed-census printout.

Filters data/results/*_{gci,arms}.csv to the frozen sample30_v3.json roster
(27 regular + 3 eccentric) and recomputes the preregistered gates:

  H1 (mesh protocol suffices): >= 90% of (model, metric) pairs in
      0.5 < p < 2.5 with GCI_fine <= 5%.
  H2: unreliable-value flag rate among rated pairs (flagged = !h1_pass);
      the protocol's value proposition under H1-fail is *flagging*, and the
      flag set is exactly the p-out set (GCI_fine never breaches 5%).
  C1 arbitration: |T_slope/T_amp - 1| <= 1.5% per model with both metrics.

Writes data/results/summary30.csv (rated pairs only) and prints the
scoreboard. Usage: python3 scripts/final_verdict.py
"""
import csv
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RESULTS = REPO / "data" / "results"
P_LO, P_HI, G_MAX = 0.5, 2.5, 5.0
METRICS = ["Bg1", "THD_pct", "T_avg_slope_Nm", "T_avg_amp_Nm",
           "lambda1_energy_Wb", "lambda_m_Wb"]


def roster():
    s = json.load(open(REPO / "data" / "sample30_v3.json"))
    return set(s["sample_regular"]) | set(s["sample_eccentric"])


def main():
    keep = roster()
    rows = []
    for fp in sorted(RESULTS.glob("*_gci.csv")):
        with open(fp) as f:
            rows += [r for r in csv.DictReader(f)
                     if r["model"] in keep and r["metric"] != "C1_slope_vs_amp"]
    rated = [r for r in rows if r["p_order"] != "" and r["GCI_fine_pct"] != ""]
    for r in rated:
        r["in_range"] = P_LO < float(r["p_order"]) < P_HI
        r["gci_ok"] = float(r["GCI_fine_pct"]) <= G_MAX
        r["h1_pass"] = r["in_range"] and r["gci_ok"]

    h1 = sum(r["h1_pass"] for r in rated)
    p_out = sum(not r["in_range"] for r in rated)
    gci_out = sum(r["in_range"] and not r["gci_ok"] for r in rated)
    both_bad = sum(not r["in_range"] and not r["gci_ok"] for r in rated)

    # solve accounting over the roster only (arms.csv: one file per model)
    solves = {"OK": 0, "FAIL": 0}
    fine = {"done": 0, "timeout": 0}
    for fp in sorted(RESULTS.glob("*_arms.csv")):
        model = fp.name.replace("_arms.csv", "")
        if model not in keep:
            continue
        for r in csv.DictReader(open(fp)):
            solved = r["Bg1"] != ""
            solves["OK" if solved else "FAIL"] += 1
            if r["arm"] == "A1" and r["mesh"] == "fine":
                fine["done" if solved else "timeout"] += 1

    # C1 over the roster
    c1_rows, c1_pass = [], 0
    for fp in sorted(RESULTS.glob("*_gci.csv")):
        with open(fp) as f:
            c1_rows += [r for r in csv.DictReader(f)
                        if r["model"] in keep and r["metric"] == "C1_slope_vs_amp"]
    for r in c1_rows:
        if r.get("C1_pass", "") != "":
            c1_pass += int(r["C1_pass"]) == 1

    out = RESULTS / "summary30.csv"
    if rated:
        keys = list(rated[0].keys())
        with open(out, "w", newline="") as f:
            w = csv.DictWriter(f, keys)
            w.writeheader()
            w.writerows(rated)

    print(f"roster {len(keep)} models; rated pairs {len(rated)}; "
          f"solves {solves['OK']}/{solves['OK']+solves['FAIL']} OK; "
          f"fine arms {fine['done']} done / {fine['timeout']} timeout")
    print(f"H1: {h1}/{len(rated)} = {100*h1/len(rated):.1f}% -> "
          f"{'PASS' if h1/len(rated) >= 0.9 else 'FAIL'} (prereg >= 90%)")
    print(f"    failure shape: p-out {p_out}, gci>5% {gci_out}, both {both_bad}")
    print(f"H2 flag rate: {(len(rated)-h1)/len(rated)*100:.1f}% "
          f"(flagged = !h1_pass; all flags carry a p-out or GCI evidence)")
    print(f"C1 arbitration: {c1_pass}/{len(c1_rows)} = "
          f"{100*c1_pass/len(c1_rows) if c1_rows else 0:.1f}% (<=1.5%)")
    print(f"-> {out}")


if __name__ == "__main__":
    main()
