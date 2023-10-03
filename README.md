# zkml-rust

```
#let workdir=/zkp
cd /zkp 

git clone https://github.com/eigmax/zkml-rust.git
git clone https://github.com/powdr-labs/powdr

(cd powdr && git checkout a001f81940c264bd615ecb1279929303d1b72857 && git apply ../zkml-rust/powdr.diff)

git clone https://github.com/0xEigenLabs/eigen-zkvm

cd zkml-rust && bash -x recursive.sh
```
