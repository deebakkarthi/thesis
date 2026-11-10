#!/bin/bash
# Master-only debug: re-run an evaluated run and list every formal-coverage
# item of the top instance that is NOT covered_and_checked, with its source
# location and expression. Writes <run_dir>/uncovered.txt.
# usage: common/list_uncovered.sh <results/iterN/<design>/runK>
set -uo pipefail
run=$(cd "$1" && pwd)
tcl=$(ls "$run"/*.tcl | head -1)
top=$(basename "$tcl" .tcl)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
grep -vE '^[[:space:]]*(report -json|exit)' "$tcl" > "$tmp/dbg.tcl"
cat >> "$tmp/dbg.tcl" <<EOF
set fh [open "$run/uncovered.txt" w]
foreach st {uncovered_or_unchecked unreachable_or_undetectable} {
  foreach id [check_cov -list -status \$st -include_instance {$top} -cid -silent] {
    set info [check_cov -get_cover_item_info \$id -name -expression -source_location]
    puts \$fh "\$st | \$info"
  }
}
close \$fh
exit -force
EOF
cd "$run"
timeout ${JG_TIMEOUT:-1200} jg -no_gui -proj "$tmp/proj" -tcl "$tmp/dbg.tcl" < /dev/null > "$tmp/dbg.log" 2>&1
grep -E "^ERROR" "$tmp/dbg.log" | head
cut -d'|' -f1 "$run/uncovered.txt" | sort | uniq -c
echo "details: $run/uncovered.txt"
