# zkml-rust

Note: make sure your server has at least 40GiB RAM.
## Requirement 

* Nodejs, 18.x
* Rust

## Run zk-LR

```
#let workdir=/zkp
cd /zkp 

git clone https://github.com/eigmax/zkml-rust.git
git clone https://github.com/eigmax/powdr
git clone https://github.com/0xEigenLabs/eigen-zkvm

cd zkml-rust && bash -x recursive.sh
```

## Performance

The proof time on a 128core server:
```
Stark proof: (168s)
Recursive proof: (38s)
Snark proof: (129s)
```
