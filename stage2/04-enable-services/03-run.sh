#!/bin/bash -e

on_chroot << EOF

systemctl enable nftables.service

EOF
