K Semantics of Eth2.0 Beacon Chain
==================================

An executable, formal specification of [Eth2.0 Beacon Chain Phase 0 specification](https://github.com/ethereum/eth2.0-specs/blob/dev/specs/core/0_beacon-chain.md) in the [K framework](http://www.kframework.org). The project provides:
- an executable model of the beacon chain state transition function that is validated against the standard test suite of the beacon chain, and
- testing and rule-based test coverage analysis on the model's K specification

The specification and test coverage analysis results are described in the technical report:

<img src="report/src/resources/pdf-icon.png" alt="PDF" width="2%" /> *[An Executable K Model of Ethereum 2.0 Beacon Chain Phase 0 Specification](https://github.com/runtimeverification/beacon-chain-spec/blob/master/report/bck-report.pdf)*


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

```

#### MacOS

In addition to the dependencies listed at [KEVM](https://github.com/kframework/evm-semantics), install:

```sh
brew install jemalloc llvm libyaml git-lfs cryptopp
```

Build K and K's dependencies, and build local version of `libsecp256k1`.

```sh
git submodule update --init --recursive
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
Files
-----

The main model files and testing scripts, which are located in the directory of this README, are as follows:

- `constants-minimal.k`: definitions of system-wide constants for testing purposes, corresponding to the "minimal" test suite of beacon chain
- `types.k`: type definitions and basic operations corresponding to Python data types and builtin functions and beacon-chain-specific types and operations needed by the model
- `config.k`: specification of a K configuration defining the structure and components of the beacon state
- `hash-tree.k`: specification of the hash-tree (merkle-tree) computation functions on beacon-chain data structures
- `beacon-chain.k`: specification of the beacon chain state transition function and all its supporting sub-functions
- `buildConfig.py`, `runTest.py`: scripts that load beacon chain implementation-independent tests into K.

Getting Help
------------
Feel free to report GitHub issues or to contact us at: contact@runtimeverification.com
