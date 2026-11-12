#!/bin/bash
# Start a new, independent optimizer run: creates results/<timestamp>/ and
# prints its absolute path. Every other script takes this path as its first
# argument, and everything the run produces stays inside it.
# usage: common/new_run.sh            (prints the run directory)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
ts=$(date +%Y%m%dT%H%M%S)
run=$ROOT/results/$ts
n=1
while ! mkdir "$run" 2>/dev/null; do run=$ROOT/results/${ts}_$n; n=$((n + 1)); done
echo "$run"
