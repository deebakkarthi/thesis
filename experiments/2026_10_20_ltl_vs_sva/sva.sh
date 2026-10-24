#!/usr/bin/env bash

PROMPT=$(<./sva.md)

results_dir="artifacts/$(date +"%Y%m%dT%H%M%S")_sva"
mkdir "$results_dir"

for i in {1..5}; do
	tmpdir=$(mktemp -d)
	cp ./sockit_owm.v "$tmpdir/"
	pushd "$tmpdir"

	unset "ANTHROPIC_API_KEY"
	claude --print \'"$PROMPT"\' --allowedTools "Read,Write,Edit,Bash" \
		--dangerously-skip-permissions

	popd
	cp "$tmpdir"/sockit_owm.sva "$results_dir/sockit_owm.sva_$i"
	rm -rf "$tmpdir"
done
