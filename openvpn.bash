#!/bin/bash
# BonvScripts
# https://github.com/Bonveio/BonvScripts

PUBLIC_INTERFACE="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
PUBLIC_IP_ADDRESS="$(curl -4sL http://ipinfo.io/ip || wget -4qO- http://ipinfo.io/ip)"

if [[ ! -e /etc/openvpn/server.conf ]]; then
 echo -e "Missing OpenVPN Server config, exiting..."
 exit 1
fi

PRIVATE_IP="$(cat /etc/openvpn/server.conf | grep -i server | sed -e '/cert.*/d' -e '/key.*/d' | awk '{printf $2}')"

CIDR_CLASS=""
if grep -qs 255.255.0.0 /etc/openvpn/server.conf; then
 CIDR_CLASS="16"
elif grep -qs 255.255.255.0 /etc/openvpn/server.conf; then
 CIDR_CLASS="24"
fi

if [[ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ]]; then
 echo 1 > /proc/sys/net/ipv4/ip_forward
fi

iptables -I FORWARD -s $PRIVATE_IP/$CIDR_CLASS -j ACCEPT

iptables -t nat -A POSTROUTING -o $PUBLIC_INTERFACE -j MASQUERADE

iptables -t nat -A POSTROUTING -s $PRIVATE_IP/$CIDR_CLASS -o $PUBLIC_INTERFACE -j MASQUERADE

#iptables -t nat -A POSTROUTING -s $PRIVATE_IP/$CIDR_CLASS -o $PUBLIC_INTERFACE -j SNAT --to-source $PUBLIC_IP_ADDRESS

# After you run this script, Connect through your client config and test if its now working
# 
