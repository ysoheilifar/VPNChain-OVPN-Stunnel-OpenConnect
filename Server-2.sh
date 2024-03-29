#!/bin/bash
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
nc='\033[0m' #No Color
OS=`hostnamectl  2>/dev/null| grep -i operating | cut -d: -f2`
if [[ $OS == *"20.04"* ]]; then
    echo -e "\n${green} Ubuntu version is$OS and OK ${nc}\n"
else
    echo -e "\n${red} Ubuntu version is$OS and not support ${nc}\n "
    exit 0
fi
read -p "Enter Server-1 IP address: " server_1
read -p "Enter Server-1 root username: " server_1_user
read -s -p "Enter Server-1 root password: " server_1_pass
apt install -y sshpass
sshpass -p "$server_1_pass" scp -o StrictHostKeyChecking=no $server_1_user@$server_1:irfree.ovpn /root/irfree.ovpn
if [[ $? == 0 ]]; then
    echo -e "\n${green} OpenVPN file Successfully download ${nc}\n"
else
    echo -e "\n${red} OpenVPN file failed to download ${nc}\n"
    exit 0
fi
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
iptables=`iptables -t nat -L | grep -e 192.168.0.0 -e 10.8.0.2`
if [[ -z $iptables ]]; then
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 192.168.0.0/21 -j SNAT --to-source 10.8.0.2
fi
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt install iptables-persistent -y
apt install net-tools -y
apt install stunnel4 -y
cat >> /etc/stunnel/stunnel.conf << EOF
output = /var/log/stunnel4/stunnel.log
pid = /var/run/stunnel4/stunnel.pid
client = yes
[openvpn]
sni = www.bing.com
accept = 127.0.0.1:1194
connect = $server_1:8080
EOF
stunnel
apt install -y openvpn 
gw=`ip route | grep default | cut -d" " -f3`
ether=`ip route | grep default | cut -d" " -f5`
ip route add $server_1 via $gw dev $ether
if [[ ! -f /root/irfree.ovpn ]]; then
    echo -e "\n${red} irfree.ovpn does not exist on /root directory \n${nc}"
    exit 0
fi
openvpn --config /root/irfree.ovpn --daemon
echo -e "\n${yellow} wait 30 second ... ${nc}\n"
sleep 30
ip route add default via 10.8.0.2 dev tun0 table 120
iprule=`ip rule show table 120 | grep 192.168.1.0/21`
if [[ -z $iprule ]]; then
    ip rule add from 192.168.1.0/21 table 120
fi
apt install -y ocserv
sed -i '/#auth = "pam"/a auth = "plain[passwd=/etc/ocserv/ocpasswd]"' /etc/ocserv/ocserv.conf
sed -ie '/auth = "pam.*/s/^/#/' /etc/ocserv/ocserv.conf
sed -ie '/^route = /,+2 s/^/#/' /etc/ocserv/ocserv.conf
sed -i 's/#route = default/route = default/' /etc/ocserv/ocserv.conf
systemctl restart ocserv
