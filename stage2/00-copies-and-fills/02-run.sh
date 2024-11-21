#!/bin/bash -e

[ -f "${ROOTFS_DIR}/etc/ld.so.preload" ] && mv "${ROOTFS_DIR}/etc/ld.so.preload" "${ROOTFS_DIR}/etc/ld.so.preload.disabled"
