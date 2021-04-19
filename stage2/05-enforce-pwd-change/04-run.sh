#!/bin/bash -e

on_chroot << EOF

chage --lastday 1970-01-01 "${FIRST_USER_NAME}"

EOF
