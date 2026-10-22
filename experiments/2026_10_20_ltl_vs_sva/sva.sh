#!/usr/bin/env bash

PROMPT=$(< ./sva.md)

tmpdir=$(mktemp -d)

cp ./sockit_owm.v "$tmpdir/"

pushd "$tmpdir"

unset "ANTHROPIC_API_KEY"

claude --print \'"$PROMPT"\' --allowedTools "Read,Write,Edit,Bash" \
	--dangerously-skip-permissions

popd 

mkdir -p artifacts/

mv "$tmpdir" "artifacts/$(date +"%Y%m%dT%H%M%S")_sva"
