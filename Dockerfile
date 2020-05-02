ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-bionic-${K_COMMIT}

RUN    apt-get update                   \
    && apt-get upgrade --yes            \
    && apt-get install --yes            \
                    autoconf            \
                    bison               \
                    clang-8             \
                    cmake               \
                    curl                \
                    flex                \
                    gcc                 \
                    git-lfs             \
                    libboost-test-dev   \
                    libcrypto++-dev     \
                    libffi-dev          \
                    libjemalloc-dev     \
                    libmpfr-dev         \
                    libprocps-dev       \
                    libsecp256k1-dev    \
                    libssl-dev          \
                    libtool             \
                    libyaml-dev         \
                    libz3-dev           \
                    lld-8               \
                    llvm-8-tools        \
                    make                \
                    maven               \
                    opam                \
                    openjdk-11-jdk      \
                    pandoc              \
                    pkg-config          \
                    python3             \
                    python3-pip         \
                    python-pip          \
                    python-pygments     \
                    python-recommonmark \
                    python-setuptools   \
                    python-sphinx       \
                    z3                  \
                    zlib1g-dev

RUN pip3 install -U PyYAML
RUN pip install sphinx_rtd_theme

RUN    cd /home/user                                                      \
    && git clone --depth=1 https://github.com/kframework/k-editor-support \
    && cd k-editor-support/pygments                                       \
    && python /usr/lib/python3/dist-packages/easy_install.py --user .

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=/home/user/.local/bin:/home/user/.cargo/bin:$PATH

RUN    git config --global user.email 'admin@runtimeverification.com' \
    && git config --global user.name  'RV Jenkins'                    \
    && mkdir -p ~/.ssh                                                \
    && echo 'host github.com'                       > ~/.ssh/config   \
    && echo '    hostname github.com'              >> ~/.ssh/config   \
    && echo '    user git'                         >> ~/.ssh/config   \
    && echo '    identityagent SSH_AUTH_SOCK'      >> ~/.ssh/config   \
    && echo '    stricthostkeychecking accept-new' >> ~/.ssh/config   \
    && chmod go-rwx -R ~/.ssh
