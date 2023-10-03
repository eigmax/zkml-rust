#!/bin/bash
set -ex

WORKSPACE="$(cd "$( dirname "$0")/.." && pwd)"

echo "1. Generate the stark proof for Rust zkVM"
cd $WORKSPACE/powdr
cargo run --release rust $WORKSPACE/zkml-rust/lr/src/main.rs -f -o ./test_lr --prove-with estark

cd $WORKSPACE/eigen-zkvm
cargo build --release
ZKIT=$WORKSPACE/eigen-zkvm/target/release/eigen-zkit

cd starkjs && npm i

cd $WORKSPACE/zkml-rust
mkdir -p test_regression && rm -rf test_regression/*
mkdir -p circuits && rm -rf circuits/*
mkdir -p $WORKSPACE/build && rm -rf $WORKSPACE/build/*

echo "2. Generate the proof for Stark verifier"
$ZKIT compile -p goldilocks -i /tmp/abc.circom -l "$WORKSPACE/eigen-zkvm/starkjs/node_modules/pil-stark/circuits.gl" -l "$WORKSPACE/eigen-zkvm/starkjs/node_modules/circomlib/circuits" --O2=full -o test_regression 

$ZKIT compressor12_setup  --r test_regression/abc.r1cs --c test_regression/c12.const  --p test_regression/c12.pil   --e test_regression/c12.exec
$ZKIT compressor12_exec --w test_regression/abc_js/abc.wasm --i /tmp/abc.zkin.json --p test_regression/c12.pil  --e test_regression/c12.exec --m test_regression/c12.cm

$ZKIT stark_prove -s lr/c12.starkStruct.bn128.json \
    -p test_regression/c12.pil.json \
    --o test_regression/c12.const \
    --m test_regression/c12.cm -c circuits/c12a.verifier.circom --i circuits/final_input.zkin.json --norm_stage


CIRCUIT=c12a.verifier
POWER=23

SRS=$WORKSPACE/setup_2^${POWER}.key

if [ ! -f $SRS ]; then
    ${ZKIT} setup -p ${POWER} -s ${SRS}
fi

echo "3. Generate the final snark proof and solidity verifier"
${ZKIT} compile -i circuits/${CIRCUIT}.circom -l "$WORKSPACE/eigen-zkvm/starkjs/node_modules/pil-stark/circuits.bn128" -l "$WORKSPACE/eigen-zkvm/starkjs/node_modules/circomlib/circuits" \
	--O2=full -o $WORKSPACE/build

${ZKIT} calculate_witness -i circuits/final_input.zkin.json -w ${WORKSPACE}/build/${CIRCUIT}_js/${CIRCUIT}.wasm -o $WORKSPACE/build/witness.wtns

${ZKIT} export_verification_key -s ${SRS}  -c $WORKSPACE/build/$CIRCUIT.r1cs --v $WORKSPACE/build/vk.bin

${ZKIT} prove -c $WORKSPACE/build/$CIRCUIT.r1cs -w $WORKSPACE/build/witness.wtns -s ${SRS} --b $WORKSPACE/build/proof.bin

${ZKIT} verify -p $WORKSPACE/build/proof.bin -v $WORKSPACE/build/vk.bin

${ZKIT} generate_verifier -v $WORKSPACE/build/vk.bin --s $WORKSPACE/build/verifier.sol

