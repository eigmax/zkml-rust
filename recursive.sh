#!/bin/bash
set -ex

# TARGET_DIR="/mnt/data/lo/powdr"

# if [ ! -d "$TARGET_DIR" ]; then
#     git clone https://github.com/powdr-labs/powdr.git "$TARGET_DIR"
#     cd "$TARGET_DIR"
#     # Install powdr_cli
#     cargo install --path ./powdr_cli
#     cd ..
# fi

# # Test regression
# powdr rust regression -o ./test_regression -f

# Test 

workdir="$(cd "$( dirname "$0")/.." && pwd)"

cd $workdir/powdr

cargo run --release rust $workdir/zkml-rust/lr/src/main.rs -f -i "3,1,1,2,2,3,1" -o ./test_sum --prove-with estark

cd ../eigen-zkvm/test
mkdir -p test_regression && rm -rf test_regression/*
../target/release/eigen-zkit compile -p goldilocks -i /tmp/abc.circom -l "../starkjs/node_modules/pil-stark/circuits.gl" -l "../starkjs/node_modules/circomlib/circuits" --O2=full -o test_regression 

../target/release/eigen-zkit compressor12_setup  --r test_regression/abc.r1cs --c test_regression/c12.const  --p test_regression/c12.pil   --e test_regression/c12.exec
../target/release/eigen-zkit compressor12_exec --w test_regression/abc_js/abc.wasm --i /tmp/abc.zkin.json --p test_regression/c12.pil  --e test_regression/c12.exec --m test_regression/c12.cm

../target/release/eigen-zkit stark_prove -s ../../zkml-rust/lr/c12.starkStruct.bn128.json \
    -p test_regression/c12.pil.json \
    --o test_regression/c12.const \
    --m test_regression/c12.cm -c circuits/c12a.verifier.circom --i circuits/c12a.verifier/final_input.zkin.json --norm_stage

bash -x ./snark_verifier.sh groth16 true bn128 c12a.verifier $PWD/circuits
