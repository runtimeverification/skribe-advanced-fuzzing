#!/usr/bin/env bash

set -euxo pipefail

export KLLVM_LIBRARY_PATH=$(kdist which stylus-semantics.llvm-library)

cd 9lives
./build-skribe.sh
skribe build
skribe run --max-examples 5

cd -

cd skribe/skribe-fuzz-rs
cargo test

cd fuzz
cargo +nightly fuzz build
