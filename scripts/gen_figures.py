#!/usr/bin/env python3
"""Paper 3 figures from released CSVs only (no hardcoded numbers).

Fig 1 protocol boundary map: per (model, metric) p_order vs GCI_fine_pct
scatter with the preregistered H1 gate lines (0.5<p<2.5, GCI=5%) -- the
paper's headline figure. Fig 2 arm comparison: per-metric spread A0 vs
A1-fine (what the bare run hides). Reads data/results/summary.csv and
*_arms.csv; every point traces to a released CSV row.

Usage: python3 scripts/gen_figures.py [--out figures]
"""
import argparse
import csv
from collections import defaultdict
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

HERE = Path(__file__).resolve().parent
RESULTS = HERE.parent / "data" / "results"
P_LO, P_HI, G_MAX = 0.5, 2.5, 5.0


def fig_boundary(out: Path):
    if not (RESULTS / "summary.csv").exists():
        print("summary.csv missing -- run analyze_ablation.py after the matrix")
        return
    pts = []
    with open(RESULTS / "summary.csv") as f:
        for r in csv.DictReader(f):
            if r["p_order"] and r["GCI_fine_pct"]:
                pts.append((float(r["p_order"]), float(r["GCI_fine_pct"]),
                            r["h1_pass"] == "True"))
    if not pts:
        print("summary.csv empty -- run analyze_ablation.py first")
        return
    fig, ax = plt.subplots(figsize=(5.4, 4.0))
    ok = [(p, g) for p, g, h in pts if h]
    bad = [(p, g) for p, g, h in pts if not h]
    ax.scatter(*zip(*ok), s=14, c="#1f77b4", label=f"gate pass ({len(ok)})")
    ax.scatter(*zip(*bad), s=14, c="#d62728", marker="x",
               label=f"flagged ({len(bad)})")
    ax.axvspan(P_LO, P_HI, color="#1f77b4", alpha=0.06)
    ax.axhline(G_MAX, color="#d62728", ls="--", lw=0.8)
    ax.axvline(P_LO, color="#888", ls=":", lw=0.8)
    ax.axvline(P_HI, color="#888", ls=":", lw=0.8)
    ax.set_xlabel("observed order $p$ (three-grid Richardson)")
    ax.set_ylabel(r"GCI$_{\rm fine}$ [%]")
    ax.set_ylim(0, max(10, max(g for _, g, _ in pts) * 1.05))
    ax.set_title("Protocol boundary: mesh+GCI gate per (model, metric)")
    ax.legend(frameon=False, fontsize=8)
    fig.tight_layout()
    fig.savefig(out / "fig_boundary.pdf")
    print("->", out / "fig_boundary.pdf", f"({len(ok)} pass / {len(bad)} flagged)")


def fig_arms(out: Path):
    """Relative deviation of A0 bare from A1-fine, per metric (box)."""
    rel = defaultdict(list)
    for fp in sorted(RESULTS.glob("*_arms.csv")):
        rows = list(csv.DictReader(open(fp)))
        by_arm = {r["arm"] + "_" + r.get("mesh", ""): r for r in rows}
        a0 = by_arm.get("A0_default")
        fine = by_arm.get("A1_fine")
        if not (a0 and fine):
            continue
        for m in ("Bg1", "THD_pct", "T_avg_slope_Nm", "lambda_m_Wb"):
            try:
                v0, vf = float(a0[m]), float(fine[m])
            except (KeyError, ValueError, TypeError):
                continue
            if vf:
                rel[m].append(100 * abs(v0 - vf) / vf)
    if not rel:
        print("arms CSVs incomplete -- waiting for matrix")
        return
    metrics = list(rel)
    fig, ax = plt.subplots(figsize=(5.6, 3.4))
    bp = ax.boxplot([rel[m] for m in metrics], tick_labels=metrics,
                    showfliers=True, flierprops={"markersize": 3})
    for med in bp["medians"]:
        med.set_color("#d62728")
    ax.set_ylabel("|A0 bare − A1 fine| / A1 fine  [%]")
    ax.set_title("What the bare run hides (per-model relative gap)")
    ax.tick_params(axis="x", labelsize=8)
    fig.tight_layout()
    fig.savefig(out / "fig_arms_gap.pdf")
    print("->", out / "fig_arms_gap.pdf",
          {m: f"n={len(v)} med={sorted(v)[len(v)//2]:.2f}%" for m, v in rel.items()})


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(HERE.parent / "figures"))
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(exist_ok=True)
    fig_boundary(out)
    fig_arms(out)
