#!/bin/bash
# Compile-only check: analyzes and elaborates the RTL together with the SVA
# checker in this directory, then exits.
# usage: ./check_syntax.sh [workspace_dir]   (default: the script's directory)
set -uo pipefail
ws=$(cd "${1:-$(dirname "$0")}" && pwd)
tcl=$(ls "$ws"/*.tcl | head -1)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# everything up to the elaborate line (analyze, optional SVA filelist, elaborate)
awk '{print} /^[[:space:]]*elaborate/{exit}' "$tcl" | grep -v '^[[:space:]]*check_cov' > "$tmp/syn.tcl"
echo "exit -force" >> "$tmp/syn.tcl"
cd "$ws"
timeout 300 jg -no_gui -proj "$tmp/proj" -tcl "$tmp/syn.tcl" < /dev/null > "$tmp/syn.log" 2>&1
grep -E "ERROR|\[WARN|WARNING" "$tmp/syn.log" | grep -v "^INFO" | sort -u | head -60
if grep -q "ERROR" "$tmp/syn.log"; then echo "SYNTAX FAIL"; exit 1; else echo "SYNTAX OK"; fi
