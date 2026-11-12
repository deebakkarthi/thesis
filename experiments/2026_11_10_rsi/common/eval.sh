#!/bin/bash
# Evaluate one generator run. Copies the workspace into results/ (out of the
# generator's view), runs the frozen design tcl there, and records metrics.
# usage: common/eval.sh <design> <iter> <k>
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
design=$1 iter=$2 k=$3
ws=$ROOT/work/iter$iter/$design/run$k
dst=$ROOT/results/iter$iter/$design/run$k
[ -d "$ws" ] || { echo "no workspace $ws" >&2; exit 1; }
rm -rf "$dst"; mkdir -p "$dst"
# generator output + frozen design inputs (taken from designs/, not the workspace)
[ -d "$ws/sva" ] && cp -r "$ws/sva" "$dst/"
[ -f "$ws/${design}_sva.f" ] && cp "$ws/${design}_sva.f" "$dst/"
cp -r "$ROOT/designs/$design/rtl" "$dst/"
cp "$ROOT/designs/$design/$design.f" "$ROOT/designs/$design/$design.tcl" "$dst/"
cp "$ROOT/GENERATOR_PROMPT.md" "$ROOT/results/iter$iter/GENERATOR_PROMPT.md"
mkdir -p "$dst/metrics"
cd "$dst"
timeout ${JG_TIMEOUT:-1200} jg -no_gui -proj "$dst/jgproject" -tcl "$design.tcl" < /dev/null > jg.log 2>&1
rc=$?
[ $rc -eq 124 ] && echo "WARNING: jg timed out after ${JG_TIMEOUT:-1200}s" | tee -a jg.log
rm -rf "$dst/jgproject"
python3 "$ROOT/common/metrics.py" "$dst" --tsv "$ROOT/results/iter$iter/summary.tsv" --tag "$design run$k"
