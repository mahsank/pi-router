#!/bin/bash -e

on_chroot << EOF

systemctl disable systemd-resolved.service
systemctl mask systemd-resolved.service
systemctl enable dnscrypt-proxy.service
systemctl enable nftables.service

EOF
