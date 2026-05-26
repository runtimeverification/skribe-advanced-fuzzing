#!/usr/bin/env bash

set -euxo pipefail

export KLLVM_LIBRARY_PATH="$(kdist which stylus-semantics.llvm-library)"
export LD_LIBRARY_PATH="${KLLVM_LIBRARY_PATH}"

FUZZ_SPEC=/home/user/fuzz-spec.json

: '########################################'
: '#  Initialization                      #'
: '########################################'

cd 9lives
./build-skribe.sh
skribe build
time skribe export-specs > "${FUZZ_SPEC}"
cd -

: '########################################'
: '#  M1: Baseline Metrics                #'
: '########################################'

time skribe run --max-examples 3 --fuzz-spec "${FUZZ_SPEC}" --id test_end_to_end_intense

: '########################################'
: '#  M2: Tighter Exec Feedback           #'
: '########################################'

cd skribe/skribe-fuzz-rs/fuzz
cargo +nightly fuzz build --release
cd -
cp skribe/skribe-fuzz-rs/target/x86_64-unknown-linux-gnu/release/fuzz_target_1 skribe-fuzz-libfuzzer
time ./skribe-fuzz-libfuzzer -runs=50 --fuzz-spec="${FUZZ_SPEC}" --contract-name=TestSkribeEndToEnd --function-name=test_end_to_end_intense

: '########################################'
: '#  M3-M4: Greybox Fuzzing w/ Coverage  #'
: '########################################'

cd skribe/skribe-fuzz-rs
cargo build --release
cd -
cp skribe/skribe-fuzz-rs/target/release/skribe-fuzz .
time ./skribe-fuzz --iterations 50 --fuzz-spec "${FUZZ_SPEC}" --contract-name TestSkribeEndToEnd --function-name test_end_to_end_intense
