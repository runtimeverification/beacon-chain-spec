FROM runtimeverificationinc/ubuntu:bionic

RUN    apt-get update                                                        \
    && apt-get upgrade --yes                                                 \
    && apt-get install --yes                                                 \
        autoconf bison clang-8 cmake curl flex gcc git-lfs libboost-test-dev \
        libcrypto++-dev libffi-dev libjemalloc-dev libmpfr-dev libprocps-dev \
        libsecp256k1-dev libssl-dev libtool libyaml-dev lld-8 llvm-8-tools   \
        make maven opam openjdk-11-jdk pandoc pkg-config python3 python3-pip \
        zlib1g-dev

ADD deps/k/haskell-backend/src/main/native/haskell-backend/scripts/install-stack.sh /.install-stack/
RUN /.install-stack/install-stack.sh

USER user:user

ADD --chown=user:user deps/k/haskell-backend/src/main/native/haskell-backend/stack.yaml /home/user/.tmp-haskell/
ADD --chown=user:user deps/k/haskell-backend/src/main/native/haskell-backend/kore/package.yaml /home/user/.tmp-haskell/kore/
RUN    cd /home/user/.tmp-haskell  \
    && stack build --only-snapshot

RUN pip3 install -U PyYAML

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/home/user/.local/bin:/home/user/.cargo/bin:$PATH
