FROM ubuntu:bionic

ENV TZ=America/Chicago
RUN    ln --symbolic --no-dereference --force /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN    apt update                                                               \
    && apt upgrade --yes                                                        \
    && apt install --yes                                                        \
        autoconf bison clang-6.0 cmake curl flex gcc git-lfs libboost-test-dev  \
        libcrypto++-dev libffi-dev libjemalloc-dev libmpfr-dev libprocps-dev    \
        libsecp256k1-dev libssl-dev libtool libyaml-dev lld-6.0 llvm-6.0-tools  \
        make maven opam openjdk-8-jdk pandoc pkg-config python3 python-pygments \
        python-recommonmark python-sphinx time zlib1g-dev protobuf-compiler     \
        libprotobuf-dev

RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN    groupadd --gid $GROUP_ID user                                        \
    && useradd --create-home --uid $USER_ID --shell /bin/sh --gid user user

USER $USER_ID:$GROUP_ID

ADD --chown=user:user deps/k/llvm-backend/src/main/native/llvm-backend/install-rust deps/k/llvm-backend/src/main/native/llvm-backend/rust-checksum /home/user/.install-rust/
RUN    cd /home/user/.install-rust \
    && ./install-rust

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/home/user/.local/bin:/home/user/.cargo/bin:$PATH
