gw=`ip route | grep default | cut -d" " -f3`
ether=`ip route | grep default | cut -d" " -f5`
ip route add 95.217.159.120 via $gw dev $ether
iptables=`iptables -t nat -L | grep -e 192.168.0.0 -e 10.8.0.2`
if [[ -z $iptables ]]; then
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 192.168.0.0/21 -j SNAT --to-source 10.8.0.2
    iptables -t nat -A POSTROUTING -s 192.168.0.0/21 -j SNAT --to-source 10.8.0.2
fi
stunnel
openvpn --config /root/irfree.ovpn --daemon
echo -e "\n wait 30 sec ... \n"
sleep 30
iprule=`ip rule show table 120`
if [[ -z $iprule  ]]; then
        ip route add default via 10.8.0.2 dev tun0 table 120
        ip rule add from 192.168.1.0/21 table 120
fi
