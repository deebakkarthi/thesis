#!/bin/bash
# Record the prompt change that opens iteration <iter> of a run.
#   <run>/iter<iter>/GENERATOR_PROMPT.md     snapshot of the prompt used in this iteration
#   <run>/iter<iter>/GENERATOR_PROMPT.patch  unified diff from the previous iteration's prompt
# The base for iteration 1 is an empty file; for N>1 it is
# <run>/iter<N-1>/GENERATOR_PROMPT.md. Plain `diff -u`; no version control.
# usage: common/prompt_patch.sh <run> <iter>
set -uo pipefail
run=$(cd "$1" && pwd) iter=$2
out=$run/iter$iter
if [ "$iter" -le 1 ]; then
  base=/dev/null
else
  base=$run/iter$((iter - 1))/GENERATOR_PROMPT.md
  [ -f "$base" ] || { echo "missing base prompt: $base" >&2; exit 1; }
fi
[ -f "$run/GENERATOR_PROMPT.md" ] || { echo "missing $run/GENERATOR_PROMPT.md" >&2; exit 1; }
mkdir -p "$out"
cp "$run/GENERATOR_PROMPT.md" "$out/GENERATOR_PROMPT.md"
diff -u --label a/GENERATOR_PROMPT.md --label b/GENERATOR_PROMPT.md \
  "$base" "$out/GENERATOR_PROMPT.md" > "$out/GENERATOR_PROMPT.patch"
[ -s "$out/GENERATOR_PROMPT.patch" ] || echo "note: prompt unchanged from $base" >&2
echo "$out/GENERATOR_PROMPT.patch ($(grep -c '^[-+][^-+]' "$out/GENERATOR_PROMPT.patch") changed lines)"
[ -f "$out/CHANGE_MESSAGE.md" ] || echo "reminder: write $out/CHANGE_MESSAGE.md" >&2
