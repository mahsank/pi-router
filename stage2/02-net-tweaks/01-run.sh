#!/bin/bash -e

CHATTR=$(command -v \chattr)
LSATTR=$(command -v \lsattr)
GREP=$(command -v \grep)
CP=$(command -v \cp)

install -v -d					"${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d"
install -v -m 644 files/dhcpcd.service		"${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d/"

install -v -d					"${ROOTFS_DIR}/etc/nftables"
#nftables rules
install -v -m 644 files/inet-nat.nft            "${ROOTFS_DIR}/etc/nftables/"
install -v -m 644 files/inet-filter.nft         "${ROOTFS_DIR}/etc/nftables/"

#dnscrypt-proxy configuration
install -v -m 644 files/resolv.conf              "${ROOTFS_DIR}/etc/"
on_chroot <<EOF
if [ ! -s /etc/systemd/system/dnscrypt-proxy.socket ]; then
    $CP /lib/systemd/system/dnscrypt-proxy.socket /etc/systemd/system/
fi
EOF

# hostapd configuration
CONF_FILE="files/hostapd.conf"
SED=$(command -v \sed)

HOSTAPD_VARS=("country_code" "ssid" "wpa_passphrase")
HOSTAPD_VALS=("$WPA_COUNTRY" "$WPA_ESSID" "$WPA_PASSWORD")

for i in $(seq 0 2)
do
    if [ $($GREP "${HOSTAPD_VARS[$i]}=$" "${CONF_FILE}") ]; then
        $SED -i "s/\(^${HOSTAPD_VARS[$i]}=\)/&${HOSTAPD_VALS[$i]}/" $CONF_FILE
    fi  
done
install -v -m 600 files/hostapd.conf            "${ROOTFS_DIR}/etc/hostapd/"

# enable debugging via serial port                                                                                                                                        
if [ "${ENABLE_DEBUG}" == "1" ]; then
    if [ ! $($GREP "enable_uart=1" "${ROOTFS_DIR}/boot/config.txt") ]; then
        echo >> "${ROOTFS_DIR}/boot/config.txt"
        echo "# enable serial port" >> "${ROOTFS_DIR}/boot/config.txt"
        echo "enable_uart=1" >> "${ROOTFS_DIR}/boot/config.txt"
    fi
fi
