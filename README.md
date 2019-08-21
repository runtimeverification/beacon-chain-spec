K Semantics of Eth2.0 Beacon Chain
==================================

Building
--------

### Dependencies

These dependencies are pulled from [KEVM](https://github.com/kframework/evm-semantics), but with `git-lfs` added.

#### Linux

```sh
apt install --yes                                                           \
    autoconf bison clang-8.0 cmake curl flex gcc git-lfs libboost-test-dev  \
    libcrypto++-dev libffi-dev libjemalloc-dev libmpfr-dev libprocps-dev    \
    libsecp256k1-dev libssl-dev libtool libyaml-dev lld-8.0 llvm-8.0-tools  \
    make maven opam openjdk-8-jdk pandoc pkg-config python3 python-pygments \
    python-recommonmark python-sphinx time zlib1g-dev protobuf-compiler     \
    libprotobuf-dev

git submodule update --init --recursive

./deps/k/llvm-backend/src/main/native/llvm-backend/install-rust
```

#### MacOS

In addition to the dependencies listed at [KEVM](https://github.com/kframework/evm-semantics), install:

```sh
brew install jemalloc llvm libyaml
```

and rust to use K's LLVM backend:

```sh
git submodule update --init --recursive

./deps/k/llvm-backend/src/main/native/llvm-backend/install-rust
```

Build K and K's dependencies, and build local version of `libsecp256k1`.

```sh
make deps libsecp256k1
```

### Building

```sh
make build
```

### Testing

Get YAML test vectors:

```sh
make test-split
```

Run the tests:

```sh
make test
```
