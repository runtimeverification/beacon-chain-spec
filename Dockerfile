FROM runtimeverificationinc/ubuntu:bionic

RUN    apt-get update                                                        \
    && apt-get upgrade --yes                                                 \
    && apt-get install --yes                                                 \
        autoconf bison clang-8 cmake curl flex gcc git-lfs libboost-test-dev \
        libcrypto++-dev libffi-dev libjemalloc-dev libmpfr-dev libprocps-dev \
        libsecp256k1-dev libssl-dev libtool libyaml-dev lld-8 llvm-8-tools   \
        make maven opam openjdk-11-jdk pandoc pkg-config python3 zlib1g-dev

USER user:user

ADD --chown=user:user deps/k/llvm-backend/src/main/native/llvm-backend/install-rust deps/k/llvm-backend/src/main/native/llvm-backend/rust-checksum /home/user/.install-rust/
RUN    cd /home/user/.install-rust \
    && ./install-rust

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/home/user/.local/bin:/home/user/.cargo/bin:$PATH

RUN pip3 install -U PyYAML
