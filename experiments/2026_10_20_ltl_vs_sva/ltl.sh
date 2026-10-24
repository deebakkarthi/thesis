#!/usr/bin/env bash

PROMPT=$(<./ltl.md)

results_dir="artifacts/$(date +"%Y%m%dT%H%M%S")_ltl"
mkdir "$results_dir"

for i in {1..5}; do
	tmpdir=$(mktemp -d)
	cp ./sockit_owm.v "$tmpdir/"
	pushd "$tmpdir"

	unset "ANTHROPIC_API_KEY"
	claude --print \'"$PROMPT"\' --allowedTools "Read,Write,Edit,Bash" \
		--dangerously-skip-permissions

	popd
	cp "$tmpdir"/sockit_owm.ltl "$results_dir/sockit_owm.ltl_$i"
	rm -rf "$tmpdir"
done
