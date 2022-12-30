#!/bin/bash
gw = `ip route | grep default | cut -d" " -f3`
ether = `ip route | grep default | cut -d" " -f5`
ip route add $server_1 via $gw dev $ether
openvpn --config /root/irfree.ovpn --daemon
ip route add default via 10.8.0.2 dev tun0 table 120
ip rule add from 192.168.1.0/21 table 120