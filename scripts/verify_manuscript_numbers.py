#!/usr/bin/env python3
"""S5 numeric verification: every number in manuscript/main.tex vs CSVs.

Recomputes each manuscript figure from data/results/ (roster = sample30_v3)
and the frozen sample note (audit layer), then asserts the manuscript's
stated values. Exit 0 = all verified.

Usage: python3 scripts/verify_manuscript_numbers.py
"""
import csv
import glob
import json
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RES = REPO / "data" / "results"
ok, bad = [], []


def check(name, got, want, tol=0.0):
    good = (got == want) if tol == 0.0 and isinstance(want, tuple) \
        else abs(got - want) <= tol
    (ok if good else bad).append(f"{name}: got {got}, manuscript {want}")


def main():
    s = json.load(open(REPO / "data" / "sample30_v3.json"))
    keep = set(s["sample_regular"]) | set(s["sample_eccentric"])

    # --- H1/H2 from summary30.csv (as written by final_verdict.py) ---
    rated = [r for r in csv.DictReader(open(RES / "summary30.csv"))]
    n = len(rated)
    h1 = sum(r["h1_pass"] == "True" for r in rated)
    check("rated pairs", n, 56)
    check("H1 pass count", h1, 42)
    check("H1 pct", 100 * h1 / n, 75.0, tol=0.05)
    check("flag pct", 100 * (n - h1) / n, 25.0, tol=0.05)
    p_out = sum(not (0.5 < float(r["p_order"]) < 2.5) for r in rated)
    gci_out = sum((0.5 < float(r["p_order"]) < 2.5)
                  and float(r["GCI_fine_pct"]) > 5 for r in rated)
    check("p-out failures", p_out, 14)
    check("GCI>5% failures", gci_out, 0)
    gs = [float(r["GCI_fine_pct"]) for r in rated]
    check("GCI median", statistics.median(gs), 0.11, tol=0.005)
    check("GCI p90", sorted(gs)[int(0.9 * len(gs))], 0.32, tol=0.006)
    check("GCI max", max(gs), 0.65, tol=0.005)
    ps = [abs(float(r["p_order"])) for r in rated]
    check("|p| median", statistics.median(ps), 1.45, tol=0.005)
    check("|p| max", max(ps), 4.52, tol=0.005)

    # --- per-metric H1 split (RQ2) ---
    per = defaultdict(lambda: [0, 0])
    for r in rated:
        per[r["metric"]][1] += 1
        per[r["metric"]][0] += r["h1_pass"] == "True"
    for met, want in [("lambda_m_Wb", (10, 10)), ("lambda1_energy_Wb", (8, 9)),
                      ("T_avg_amp_Nm", (7, 9)), ("T_avg_slope_Nm", (7, 8)),
                      ("Bg1", (6, 10)), ("THD_pct", (4, 10))]:
        check(f"H1 {met}", tuple(per[met]), want)

    # --- eccentric holdout (RQ2) ---
    ecc = [r for r in rated if r["model"] in set(s["sample_eccentric"])]
    check("eccentric pairs", len(ecc), 5)
    check("eccentric pass", sum(r["h1_pass"] == "True" for r in ecc), 4)

    # --- C1 (RQ3) ---
    c1 = [r for fp in RES.glob("*_gci.csv") if (m := fp.name.replace("_gci.csv", "")) in keep
          for r in csv.DictReader(open(fp)) if r["metric"] == "C1_slope_vs_amp"
          and r.get("C1_pass", "") != ""]
    check("C1 evaluated", len(c1), 8)
    check("C1 pass", sum(r["C1_pass"] == "1" for r in c1), 8)

    # --- RQ1 offsets + fine-arm accounting (arms.csv, roster) ---
    diffs = defaultdict(list)
    fine_done = fine_to = 0
    for fp in RES.glob("*_arms.csv"):
        model = fp.name.replace("_arms.csv", "")
        if model not in keep:
            continue
        rows = list(csv.DictReader(open(fp)))
        a0 = next((r for r in rows if r["arm"] == "A0"), None)
        fn = next((r for r in rows if r["arm"] == "A1" and r["mesh"] == "fine"), None)
        for r in rows:
            if r["arm"] == "A1" and r["mesh"] == "fine":
                fine_done += r["Bg1"] != ""
                fine_to += r["Bg1"] == ""
        if a0 and fn and a0["Bg1"]:
            for met in ["Bg1", "THD_pct", "T_avg_slope_Nm", "lambda_m_Wb"]:
                if a0[met] and fn[met] and abs(float(a0[met])) > 1e-9:
                    diffs[met].append(
                        abs(float(fn[met]) - float(a0[met])) / abs(float(a0[met])) * 100)
    check("fine done", fine_done, 10)
    check("fine timeout", fine_to, 20)
    for met, med, mx in [("Bg1", 0.155, 0.27), ("THD_pct", 0.152, 0.52),
                         ("T_avg_slope_Nm", 0.083, 0.10), ("lambda_m_Wb", 0.072, 0.10)]:
        check(f"offset {met} median", statistics.median(diffs[met]), med, tol=0.0005)
        check(f"offset {met} max", max(diffs[met]), mx, tol=0.005)

    # --- audit layer numbers (frozen sample note) ---
    note = s["note"]
    m = re.search(r"(\d+)/(\d+)\((\d+)%\)", note)
    check("audit numerator", int(m.group(1)), 1254)
    check("audit denominator", int(m.group(2)), 1597)
    check("audit pct rounded", round(100 * int(m.group(1)) / int(m.group(2))), int(m.group(3)))

    # --- manuscript literal scan: the headline numbers must appear ---
    tex = open(REPO / "manuscript" / "main.tex").read()
    for lit in ["75.0", "42/56", "25.0\\%", "0.11", "0.65", "1.45", "4.52",
                "8/8", "4/5", "20/30", "1{,}254", "1{,}597", "79\\%"]:
        if lit.replace("\\\\", "\\") not in tex and lit not in tex:
            bad.append(f"literal missing in main.tex: {lit}")
        else:
            ok.append(f"literal present: {lit}")

    print(f"PASS {len(ok)}")
    for b in bad:
        print("FAIL", b)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
