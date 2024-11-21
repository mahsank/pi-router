#!/bin/bash -e

[ ! -d "${ROOTFS_DIR}" ] && bootstrap "${RELEASE}" "${ROOTFS_DIR}" http://raspbian.raspberrypi.org/raspbian/
