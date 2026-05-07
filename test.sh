#!/usr/bin/env bash

set -euxo pipefail

export KLLVM_LIBRARY_PATH="$(kdist which stylus-semantics.llvm-library)"
export LD_LIBRARY_PATH="${KLLVM_LIBRARY_PATH}"

cd 9lives
./build-skribe.sh
skribe build
time skribe export-specs > ../skribe/skribe-fuzz-rs/fuzz-spec.json
skribe run --max-examples 3 || true

cd -

cd skribe/skribe-fuzz-rs
cargo test

cd fuzz
cargo +nightly fuzz build
cd ..
cp target/x86_64-unknown-linux-gnu/release/fuzz_target_1 skribe-fuzz
time ./skribe-fuzz -runs=100 --fuzz-spec=fuzz-spec.json --contract-name=TestSkribeEndToEnd --function-name=test_end_to_end_intense
