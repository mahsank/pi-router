ARG BASE_IMAGE=debian:buster
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND noninteractive

RUN cat /etc/resolv.conf && apt-get -y update && \
    apt-get -y install --no-install-recommends \
        git vim parted \
        quilt coreutils qemu-user-static debootstrap zerofree zip dosfstools \
        bsdtar libcap2-bin rsync grep udev xz-utils curl xxd file kmod bc\
        binfmt-support ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY . /pi-router/

VOLUME [ "/pi-router/work", "/pi-router/deploy"]
