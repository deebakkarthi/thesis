#!/usr/bin/env bash

PROMPT=$(< ./ltl.md)

tmpdir=$(mktemp -d)

cp ./sockit_owm.v "$tmpdir/"

pushd "$tmpdir"

unset "ANTHROPIC_API_KEY"

claude --print \'"$PROMPT"\' --allowedTools "Read,Write,Edit,Bash" \
	--dangerously-skip-permissions

popd 

mkdir -p artifacts/

cp -r "$tmpdir" artifacts/

rm -rf "$tmpdir"
