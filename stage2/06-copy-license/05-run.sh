#!/bin/bash -e

# distribute license as part of binary
install -v -m 644 files/LICENSE "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/"
