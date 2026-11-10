#!/usr/bin/env python3
"""Aggregate results/iter*/summary.tsv into RESULTS.md (mean and min over runs).
usage: common/summarize.py            (rewrites RESULTS.md at the repo root)
"""
import csv, glob, os, re, statistics as st
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pct = lambda n, t: 100.0 * n / t if t else float("nan")

rows = []
for tsv in sorted(glob.glob(os.path.join(ROOT, "results", "iter*", "summary.tsv")),
                  key=lambda p: int(re.search(r"iter(\d+)", p).group(1))):
    it = int(re.search(r"iter(\d+)", tsv).group(1))
    groups = defaultdict(list)
    for r in csv.DictReader(open(tsv), delimiter="\t"):
        groups[r["tag"].split()[0]].append(r)
    for design, rs in groups.items():
        ok = [r for r in rs if r["status"] == "ok"]
        def agg(f):
            v = [f(r) for r in ok]
            return (f"{st.mean(v):.1f} / {min(v):.1f}") if v else "-"
        rows.append((it, design, f"{len(ok)}/{len(rs)}",
                     agg(lambda r: pct(int(r["proven"]), int(r["asserts"]))),
                     agg(lambda r: pct(int(r["covered"]), int(r["covers"]))),
                     agg(lambda r: pct(int(r["nonvac"]), int(r["precond"]))),
                     agg(lambda r: pct(int(r["fc"]), int(r["fc_tot"]) - int(r["fc_undet"])))))

out = ["# Results", "",
       "Each cell is mean / min over the runs that produced metrics.", "",
       "| iter | design | runs ok | proven % | covered % | non-vacuous % | formal % of achievable |",
       "|---|---|---|---|---|---|---|"]
out += [f"| {' | '.join(map(str, r))} |" for r in rows]
open(os.path.join(ROOT, "RESULTS.md"), "w").write("\n".join(out) + "\n")
print("\n".join(out))
