#!/usr/bin/env python3
"""Stratified 30-model sampler for Paper 3 (frozen plan 'Stratified sample').

Deterministic: sort by id, round-robin across slot-families for 27 regular
models, first-3-sorted eccentric models. Writes data/sample30.json.
Library path is a runtime argument (repo does not hard-code checkout paths).
"""
import argparse
import json
import re
from pathlib import Path

SEED = 20261003
N_REG = 27
N_ECC = 3
SLOT_RE = re.compile(r"(\d+)s(\d+)p")


def stratum_of(name: str) -> str:
    m = SLOT_RE.search(name)
    return f"{m.group(1)}s{m.group(2)}p" if m else "other"


def pick(lib: Path) -> dict:
    files = sorted(lib.glob("*.json"))
    names = [f.stem for f in files]
    ecc = sorted(n for n in names if "ecc" in n)
    reg = sorted(n for n in names if "ecc" not in n)
    strata = {}
    for n in reg:
        strata.setdefault(stratum_of(n), []).append(n)
    queues = {k: list(v) for k, v in sorted(strata.items())}
    keys = list(queues)
    picked, i = [], 0
    while len(picked) < N_REG and any(queues.values()):
        k = keys[i % len(keys)]
        if queues[k]:
            picked.append(queues[k].pop(0))
        i += 1
    return {
        "seed": SEED, "frozen": "2026-10-03",
        "population": {"files": len(files), "regular": len(reg), "ecc": len(ecc)},
        "strata": {k: len(v) for k, v in sorted(strata.items())},
        "sample_regular": picked, "sample_eccentric": ecc[:N_ECC],
    }


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--lib", required=True, help="path to models/library dir")
    ap.add_argument("--out", default=str(Path(__file__).resolve().parents[1] / "data/sample30.json"))
    a = ap.parse_args()
    lib = Path(a.lib)
    assert lib.is_dir(), f"library not found: {lib}"
    res = pick(lib)
    Path(a.out).parent.mkdir(exist_ok=True)
    Path(a.out).write_text(json.dumps(res, indent=2, ensure_ascii=False))
    print(f"population {res['population']}  strata {len(res['strata'])}")
    print(f"regular({len(res['sample_regular'])}): {res['sample_regular'][:4]} ...")
    print(f"eccentric({len(res['sample_eccentric'])}): {res['sample_eccentric']}")
    print("->", a.out)
