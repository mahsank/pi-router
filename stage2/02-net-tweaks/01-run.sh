#!/bin/bash -e

CHATTR=$(command -v \chattr)
LSATTR=$(command -v \lsattr)
GREP=$(command -v \grep)
CP=$(command -v \cp)

install -v -d					"${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d"
install -v -m 644 files/dhcpcd.service		"${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d/"

install -m 644 files/dhcp6c.conf		"${ROOTFS_DIR}/etc/wide-dhcpv6/"

install -v -d					"${ROOTFS_DIR}/etc/nftables"
#nftables rules
install -v -m 644 files/inet-nat.nft            "${ROOTFS_DIR}/etc/nftables/"
install -v -m 644 files/inet-filter.nft         "${ROOTFS_DIR}/etc/nftables/"

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
on_chroot << EOF
if [ "${ENABLE_DEBUG}" == "1" ]; then
    if [ ! $($GREP "enable_uart=1" "/boot/config.txt") ]; then
        echo >> "/boot/config.txt"
        echo "# enable serial port" >> "/boot/config.txt"
        echo "enable_uart=1" >> "/boot/config.txt"
    fi
fi
EOF
