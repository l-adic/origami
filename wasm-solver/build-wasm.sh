#!/usr/bin/env bash
set -e
WDIR="$(mktemp -d)"
trap 'rm -rf -- "$WDIR"' EXIT

wasm32-wasi-cabal build exe:wasm-solver --minimize-conflict-set
wasm32-wasi-cabal list-bin exe:wasm-solver
ADDER_WASM="$(wasm32-wasi-cabal list-bin exe:wasm-solver)"
wizer \
    --allow-wasi --wasm-bulk-memory true \
    "$ADDER_WASM" -o "$WDIR/adder-init.wasm" \
#    --mapdir /::./extract-hackage-info
if [ $# -eq 0 ]; then
    ADDER_WASM_OPT="$WDIR/adder-init.wasm"
else
    ADDER_WASM_OPT="$WDIR/adder-opt.wasm"
    wasm-opt "$@" "$WDIR/adder-init.wasm" -o "$ADDER_WASM_OPT"
fi
cp "$ADDER_WASM_OPT" ../circuit.wasm

