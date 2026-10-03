#!/usr/bin/env python3
"""Aggregate ablation results -> preregistered H1/H2 verdicts (Paper 3).

Reads data/results/*_gci.csv (+ *_arms.csv for FAIL accounting), writes
data/results/summary.csv and prints the H1/H2 scoreboard.

  H1 (mesh protocol suffices): >= 90% of (model, metric) pairs land in the
      asymptotic range 0.5 < p < 2.5 with GCI_fine <= 5%.
  H2 (full protocol flags unreliable values): pairs violating H1's gate
      (out-of-range p or GCI > 5%) are exactly the values the protocol
      flags; report the flag rate.

Usage: python3 scripts/analyze_ablation.py
"""
import csv
import json
from pathlib import Path

RESULTS = Path(__file__).resolve().parents[1] / "data" / "results"
P_LO, P_HI, G_MAX = 0.5, 2.5, 5.0


def main():
    rows = []
    for fp in sorted(RESULTS.glob("*_gci.csv")):
        with open(fp) as f:
            rows += [r for r in csv.DictReader(f)
                     if r["metric"] != "C1_slope_vs_amp"]
    rated = [r for r in rows if r["p_order"] != "" and r["GCI_fine_pct"] != ""]
    for r in rated:
        r["p_order"] = float(r["p_order"])
        r["GCI_fine_pct"] = float(r["GCI_fine_pct"])
        r["in_range"] = P_LO < r["p_order"] < P_HI
        r["gci_ok"] = r["GCI_fine_pct"] <= G_MAX
        r["h1_pass"] = r["in_range"] and r["gci_ok"]
    n = len(rated)
    h1 = sum(r["h1_pass"] for r in rated)
    # FAIL accounting from arms files
    solves, fails = 0, 0
    for fp in sorted(RESULTS.glob("*_arms.csv")):
        with open(fp) as f:
            for r in csv.DictReader(f):
                solves += 1
                fails += int(r.get("FAIL", 0) == "1")
    c1 = []
    for fp in sorted(RESULTS.glob("*_gci.csv")):
        with open(fp) as f:
            c1 += [r for r in csv.DictReader(f)
                   if r["metric"] == "C1_slope_vs_amp"]
    c1_pass = sum(int(r.get("C1_pass", 0) == "1") for r in c1)

    out = RESULTS / "summary.csv"
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, ["model", "metric", "p_order", "GCI_fine_pct",
                               "in_range", "gci_ok", "h1_pass"])
        w.writeheader()
        w.writerows(rated)

    print(f"pairs rated: {n}  (solves {solves - fails}/{solves} OK, "
          f"{fails} FAIL)")
    if n:
        print(f"H1: {h1}/{n} = {100*h1/n:.1f}% pass "
              f"(gate: {P_LO}<p<{P_HI} and GCI<={G_MAX}%) "
              f"-> {'PASS' if h1/n >= 0.9 else 'FAIL'} (prereg >= 90%)")
        bad = n - h1
        print(f"H2: protocol flags {bad}/{n} = {100*bad/n:.1f}% "
              f"unreliable-value rate (flagged = !h1_pass)")
    if c1:
        print(f"C1 arbitration (slope vs amp <=1.5%): {c1_pass}/{len(c1)} "
              f"= {100*c1_pass/len(c1):.1f}% pass")
    print("->", out)


if __name__ == "__main__":
    main()
