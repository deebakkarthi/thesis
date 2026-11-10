#!/bin/bash
# Create a fresh, isolated workspace for one slave run.
# usage: common/prepare.sh <design> <iter> <k>
# prints the workspace path (absolute) on stdout.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
design=$1 iter=$2 k=$3
src=$ROOT/designs/$design
[ -d "$src" ] || { echo "no such design: $src" >&2; exit 1; }
ws=$ROOT/work/iter$iter/$design/run$k
rm -rf "$ws"
mkdir -p "$ws"
# copy only the design inputs (never metrics/, jgproject/, sva/)
cp -r "$src/rtl" "$ws/"
cp "$src/$design.f" "$src/$design.tcl" "$ws/"
echo "$ws"
