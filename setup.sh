#!/bin/bash


if [ "$EUID" -ne 0 ]
	then echo "Your are not a root user....give root permissions to run this script"
	exit
fi

echo "Enter the SSID for your hotspot"
read SSID
echo "Enter password for $SSID"
read PASSWD

# This package automatically mounts USB devices on Pi
apt-get install usbmount


apt-get remove --purge hostapd
apt-get install hostapd dnsmasq

echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf
#sed -i -- 's/denyinterfaces wlan0//g' /etc/dhcpd.conf

sed -i -- 's/allow-hotplug wlan0//g' /etc/network/interfaces
sed -i -- 's/iface wlan0 inet static//g' /etc/network/interfaces


cat >> /etc/network/interfaces <<EOF
	
	allow-hotplug wlan0
	iface wlan0 inet static
	address 172.24.1.1
	netmask 255.255.255.0
	network 172.24.1.0
	broadcast 172.24.1.255
EOF

# Restart dhcpd 
service dhcpd restart

# Reload wlan0 configuration
ifdown wlan0
ifup wlan0


# make a backup of hostapd.conf
echo "backing up hostapd.conf"
file1 = "/etc/hostapd/hostapd.conf.orig"
if [ -e $file1 ]; then
	mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak
fi 

mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.orig

cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
hw_mode=g
channel=6
wnp_enabled=1
auth_algs=3
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=$PASSWD
ssid=$SSID
EOF

# make a backup of dnsmasq.conf
echo "backing up dnsmasq.conf"
file2 = "/etc/hostapd/hostapd.conf.orig"
if [ -e $file2 ]; then
	mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
fi 

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig



cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=172.24.1.50,172.24.1.150,12h
EOF


systemctl enable hostapd

echo "Reboot raspberry pi"
