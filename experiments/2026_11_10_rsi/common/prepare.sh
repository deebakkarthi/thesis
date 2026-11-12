#!/bin/bash
# Create a fresh, isolated workspace for one generator run, OUTSIDE the
# experiment tree, containing nothing that reveals evaluation:
#   rtl/, doc/, <top>.f, <top>.tcl (setup only: analyze/elaborate/clock/reset),
#   check_syntax.sh, TASK.md (copy of <run>/GENERATOR_PROMPT.md)
# A symlink <run>/work/iter<iter>/<design>/run<k> -> workspace is kept for eval.sh.
# usage: common/prepare.sh <run> <design> <iter> <k>   (prints the workspace path)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
run=$(cd "$1" && pwd) design=$2 iter=$3 k=$4
src=$ROOT/designs/$design
[ -d "$src" ] || { echo "no such design: $src" >&2; exit 1; }
[ -f "$run/GENERATOR_PROMPT.md" ] || { echo "missing $run/GENERATOR_PROMPT.md" >&2; exit 1; }
base=${SVA_WS_ROOT:-/tmp/$USER/sva_ws}
mkdir -p "$base"
ws=$(mktemp -d "$base/${design}_XXXXXX")
cp -r "$src/rtl" "$ws/"
cp "$src/$design.f" "$ws/"
# documentation: every other file in the design directory (any name)
mkdir -p "$ws/doc"
find "$src" -maxdepth 1 -type f ! -name "$design.f" ! -name "$design.tcl" \
  -exec cp {} "$ws/doc/" \;
# strip everything that measures or reports results
grep -vE '^[[:space:]]*(check_cov|prove|report|sanity_check|exit|get_|visualize)' \
  "$src/$design.tcl" > "$ws/$design.tcl"
cp "$ROOT/common/syntax_check.sh" "$ws/check_syntax.sh"
cp "$run/GENERATOR_PROMPT.md" "$ws/TASK.md"
link=$run/work/iter$iter/$design/run$k
mkdir -p "$(dirname "$link")"
rm -rf "$link"
ln -s "$ws" "$link"
echo "$ws"
