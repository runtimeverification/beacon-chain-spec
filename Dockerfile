ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-bionic-${K_COMMIT}

RUN    sudo apt-get update                      \
    && sudo apt-get upgrade --yes               \
    && sudo apt-get install --yes               \
                            git-lfs             \
                            pandoc              \
                            python3             \
                            python3-pip         \
                            python-pip          \
                            python-pygments     \
                            python-recommonmark \
                            python-setuptools   \
                            python-sphinx

RUN    pip3 install -U PyYAML       \
    && pip install sphinx_rtd_theme

ADD --chown=user:user deps/k-editor-support/pygments /home/user/.pygments
RUN cd ~/.pygments && python /usr/lib/python3/dist-packages/easy_install.py --user .

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
