#!/bin/bash -e

install -m 644 files/resolv.conf "${ROOTFS_DIR}/etc/"

on_chroot << EOF
  chattr +i /etc/resolv.conf
EOF
