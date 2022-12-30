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
apt update -y && apt upgrade -y
iptables=`iptables -nvL | grep -e 8080 -e icmp`
if [[ -z $iptables ]]; then
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -P INPUT DROP
fi
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt install iptables-persistent -y
apt install net-tools -y
cat >> /etc/sysctl.d/50-bbr.conf << EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
OVPN=`apt list --installed | grep -i openvpn`
if [[ $OVPN != *"openvpn"* ]]; then
wget https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
printf '\nn\n1\n2\n9\nn\nn\n\nirfree\n1\n' | ./openvpn-install.sh
else
    echo -e "\n${yellow}Remove OpenVPN first and run script again .${nc}\n"
    exit 0
fi
sed -i '/1194/d' /etc/iptables/add-openvpn-rules.sh
sed -i '/1194/d' /etc/iptables/rm-openvpn-rules.sh
sed -i 's/push "redirect-gateway def1 bypass-dhcp"/#push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server.conf
sed -i 's/^remote.*1194/remote 127.0.0.1 1194/' ./irfree.ovpn
apt install stunnel4 -y
cd /etc/stunnel
openssl genrsa -out key.pem 2048
printf '\n\n\n\n\n\n\n' | openssl req -new -x509 -key key.pem -out cert.pem -days 3650
cat >> /etc/stunnel/stunnel.conf << EOF
pid = /var/run/stunnel4/stunnel.pid
output = /var/log/stunnel4/stunnel.log
setuid = stunnel4
setgid = stunnel4
[openvpn]
cert=/etc/stunnel/cert.pem
key=/etc/stunnel/key.pem
accept = 0.0.0.0:8080
connect = 127.0.0.1:1194
EOF
echo 'ENABLED=1' >> /etc/default/stunnel4
stunnel
cp -rf./irfree.ovpn /root/irfree.ovpn
echo -e '\n'
read -p "Do you want to reboot? [y/n]: " yn
case $yn in
    [Yy] ) reboot;;
    [Nn] ) exit;;
    * ) echo "Please answer y or n ";;
esac
