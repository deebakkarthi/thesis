#!/usr/bin/env python3
"""Summarise one evaluated run directory (results/iterN/<design>/runK).

Metrics, in priority order:
  1. proven %   = proven / user asserts
  2. covered %  = covered / user covers   (tool-generated ':precondition'
                  vacuity covers are reported separately as 'nonvacuous %')
  3. formal %   = covered_and_checked / (total - unreachable_or_undetectable)
                  for the top-level RTL instance (raw % also shown)
"""
import argparse, glob, json, os, re, sys

ap = argparse.ArgumentParser()
ap.add_argument("run_dir")
ap.add_argument("--tsv", help="append a row to this TSV file")
ap.add_argument("--tag", default="")
a = ap.parse_args()

run = a.run_dir
top = os.path.basename(glob.glob(os.path.join(run, "*.tcl"))[0])[:-4]
pct = lambda n, t: 100.0 * n / t if t else float("nan")

row = dict(tag=a.tag or run, status="ok")
jsons = sorted(glob.glob(os.path.join(run, "metrics", "*.json")))
log = open(os.path.join(run, "jg.log"), errors="replace").read() if os.path.exists(os.path.join(run, "jg.log")) else ""

if not os.path.exists(os.path.join(run, f"{top}_sva.f")):
    row["status"] = "no_sva"
if not jsons:
    row["status"] = "no_metrics" if row["status"] == "ok" else row["status"]
    print(f"{row['tag']}: {row['status']} (see {run}/jg.log)")
    if a.tsv:
        os.makedirs(os.path.dirname(a.tsv), exist_ok=True)
        new = not os.path.exists(a.tsv)
        with open(a.tsv, "a") as f:
            if new: f.write("tag\tstatus\tproven\tasserts\tcovered\tcovers\tnonvac\tprecond\tfc\tfc_tot\tfc_undet\n")
            f.write(f"{row['tag']}\t{row['status']}\t\t\t\t\t\t\t\t\t\n")
    sys.exit(0)

d = json.load(open(jsons[-1]))
s = d["fpv"]["summary"]

# per-property outcome from the log (user vs ':precondition' covers)
def names(pat):
    return set(re.findall(pat, log))
cov_ok   = names(r'cover property "([^"]+)" was covered')
cov_unr  = names(r'(?:cover )?property "([^"]+)" was proven unreachable') | names(r'"([^"]+)" (?:is|was found) unreachable')
cex      = names(r'counterexample \(cex\)[^"]*"([^"]+)"')
user_cov_ok  = {n for n in cov_ok  if ":precondition" not in n}
user_cov_unr = {n for n in cov_unr if ":precondition" not in n}
pre_ok   = {n for n in cov_ok  if ":precondition" in n}
pre_unr  = {n for n in cov_unr if ":precondition" in n}

asserts_total, proven = s["asserts"]["total"], s["asserts"]["proven"]
covers_total = s["covers"]["total"]
n_pre = len(pre_ok | pre_unr)
user_covers_total = covers_total - n_pre if n_pre else covers_total
user_covered = s["covers"]["covered"] - len(pre_ok) if n_pre else s["covers"]["covered"]

fc = None
for cs in d["cov"]["task"][0]["coverage_summary"]:
    if cs.get("instance_name") == top:
        fc = cs["formal_coverage_local"]
fc_cc = fc["covered_and_checked"] if fc else 0
fc_tot = fc["total"] if fc else 0
fc_und = fc["unreachable_or_undetectable"] if fc else 0

row.update(proven=proven, asserts=asserts_total, covered=user_covered, covers=user_covers_total,
           nonvac=len(pre_ok), precond=n_pre, fc=fc_cc, fc_tot=fc_tot, fc_undet=fc_und)

print(f"== {row['tag']}  ({jsons[-1]})")
print(f"proven      {proven}/{asserts_total}  {pct(proven, asserts_total):.1f}%"
      f"   cex={s['asserts']['cex']} undetermined={s['asserts']['undetermined']}")
print(f"covered     {user_covered}/{user_covers_total}  {pct(user_covered, user_covers_total):.1f}%"
      f"   (user covers)")
print(f"nonvacuous  {len(pre_ok)}/{n_pre}  {pct(len(pre_ok), n_pre):.1f}%   (assert antecedents reachable)")
print(f"formal      {fc_cc}/{fc_tot - fc_und}  {pct(fc_cc, fc_tot - fc_und):.1f}% of achievable"
      f"   (raw {fc_cc}/{fc_tot} {pct(fc_cc, fc_tot):.1f}%, {fc_und} unreachable/undetectable)")
for label, ns in (("CEX", cex), ("UNREACHABLE cover", user_cov_unr), ("VACUOUS assert", pre_unr)):
    for n in sorted(ns):
        print(f"  {label}: {n}")
if row["status"] != "ok":
    print(f"  STATUS: {row['status']}")

if a.tsv:
    os.makedirs(os.path.dirname(a.tsv), exist_ok=True)
    new = not os.path.exists(a.tsv)
    with open(a.tsv, "a") as f:
        cols = ["tag", "status", "proven", "asserts", "covered", "covers", "nonvac", "precond", "fc", "fc_tot", "fc_undet"]
        if new: f.write("\t".join(cols) + "\n")
        f.write("\t".join(str(row[c]) for c in cols) + "\n")
