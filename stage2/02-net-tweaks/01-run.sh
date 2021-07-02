#!/bin/bash -e

GREP=$(command -v \grep)

# wan interface configuration for usb attached ethernet adapter usually named as `eth1`
if [ "${WAN_INTERFACE}" !=  "eth0" ]; then
    $SED -i "s/eth0/${WAN_INTERFACE}/" 00-debconf
    DIR_NAMES=("00-patches" "files")
    for j in $(seq 0 1)
    do
        for k in $(ls "${DIR_NAMES[$j]}")
        do
            $SED -i "s/eth0/${WAN_INTERFACE}/g" "${DIR_NAMES[$j]}/$k"
        done
    done
fi

install -v -d                                   "${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d"
install -v -m 644 files/dhcpcd.service          "${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d/"

install -m 644 files/dhcp6c.conf                "${ROOTFS_DIR}/etc/wide-dhcpv6/"

install -v -d                                   "${ROOTFS_DIR}/etc/nftables"
#nftables rules
install -v -m 644 files/inet-nat.nft            "${ROOTFS_DIR}/etc/nftables/"
install -v -m 644 files/inet-filter.nft         "${ROOTFS_DIR}/etc/nftables/"

# hostapd configuration
CONF_FILE="files/hostapd.conf"
SED="$(command -v \sed)"

HOSTAPD_VARS=("country_code" "ssid" "wpa_passphrase")
HOSTAPD_VALS=("$WPA_COUNTRY" "$WPA_ESSID" "$WPA_PASSWORD")

for i in $(seq 0 2)
do
    if [ "$($GREP "${HOSTAPD_VARS[$i]}=$" "${CONF_FILE}")" ]; then
        $SED -i "s/\(^${HOSTAPD_VARS[$i]}=\)/&${HOSTAPD_VALS[$i]}/" $CONF_FILE
    fi
done
install -v -m 600 files/hostapd.conf            "${ROOTFS_DIR}/etc/hostapd/"

# enable debugging
if [ "${ENABLE_DEBUG}" == "1" ]; then
on_chroot << "EOF"
    GREP=$(command -v \grep)
    SED=$(command -v \sed)
    CONFIG="/boot/config.txt"
    # enable debugging via serial port
    if [ ! $("$GREP" "enable_uart=1" "$CONFIG") ]; then
        echo >> "$CONFIG"
        echo "# enable serial port" >> "$CONFIG"
        echo "enable_uart=1" >> "$CONFIG"
    fi
    # enable debugging via spi
    if [ ! $(grep "^dtparam=spi=on$" "$CONFIG") ]; then
        $SED -i 's/#dtparam=spi/dtparam=spi/g' "$CONFIG"
    fi
EOF
fi
