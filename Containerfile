FROM docker.io/library/fedora:41

RUN dnf -y install \
    bash \
    coreutils \
    diffutils \
    findutils \
    jq \
    pipewire-utils \
    pulseaudio-utils \
    systemd \
    tar \
  && dnf clean all

WORKDIR /opt/linein-passthrough

COPY . /opt/linein-passthrough

RUN chmod +x \
    /opt/linein-passthrough/bin/linein-passthrough \
    /opt/linein-passthrough/bin/linein-passthrough-install \
    /opt/linein-passthrough/bin/linein-passthrough-uninstall \
    /opt/linein-passthrough/libexec/linein-passthrough-refresh \
    /opt/linein-passthrough/scripts/container-entrypoint.sh

ENTRYPOINT ["/opt/linein-passthrough/scripts/container-entrypoint.sh"]
CMD ["help"]
