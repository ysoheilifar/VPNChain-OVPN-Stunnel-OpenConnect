#!/bin/bash
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
nc='\033[0m' #No Color
read -p "Enter Server-1 IP address: " server_1
gw=`ip route | grep default | cut -d" " -f3`
ether=`ip route | grep default | cut -d" " -f5`
iproute=`ip route | grep 95.217.159.120`
if [[ -z $iproute ]]; then
    ip route add $server_1 via $gw dev $ether
fi
iptables=`iptables -t nat -L | grep -e 192.168.0.0 -e 10.8.0.2`
if [[ -z $iptables ]]; then
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 192.168.0.0/21 -j SNAT --to-source 10.8.0.2
    iptables -t nat -A POSTROUTING -s 192.168.0.0/21 -j SNAT --to-source 10.8.0.2
fi
stunnel
openvpn --config /root/irfree.ovpn --daemon
echo -e "\n${yellow} wait 30 sec ... ${nc}\n"
sleep 30
iprule=`ip rule show table 120`
if [[ -z $iprule  ]]; then
        ip route add default via 10.8.0.2 dev tun0 table 120
        ip rule add from 192.168.1.0/21 table 120
fi
