ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-bionic-${K_COMMIT}

RUN    apt-get update                      \
    && apt-get upgrade --yes               \
    && apt-get install --yes               \
                       cmake               \
                       git-lfs             \
                       libcrypto++-dev     \
                       libprocps-dev       \
                       libsecp256k1-dev    \
                       libssl-dev          \
                       pandoc              \
                       pkg-config          \
                       python3             \
                       python3-pip         \
                       python-pip          \
                       python-pygments     \
                       python-recommonmark \
                       python-setuptools   \
                       python-sphinx

RUN    pip3 install --upgrade PyYAML \
    && pip install sphinx_rtd_theme

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g $GROUP_ID user && useradd -m -u $USER_ID -s /bin/sh -g user user

USER user:user
WORKDIR /home/user

ADD --chown=user:user deps/k-editor-support/pygments /home/user/.pygments
RUN cd ~/.pygments && python /usr/lib/python3/dist-packages/easy_install.py --user .

RUN    git config --global user.email 'admin@runtimeverification.com' \
    && git config --global user.name  'RV Jenkins'                    \
    && mkdir -p ~/.ssh                                                \
    && echo 'host github.com'                       > ~/.ssh/config   \
    && echo '    hostname github.com'              >> ~/.ssh/config   \
    && echo '    user git'                         >> ~/.ssh/config   \
    && echo '    identityagent SSH_AUTH_SOCK'      >> ~/.ssh/config   \
    && echo '    stricthostkeychecking accept-new' >> ~/.ssh/config   \
    && chmod go-rwx -R ~/.ssh
