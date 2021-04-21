#!/bin/bash

# =========================================================
# System Request:CentOS 7+ 、Debian 8+、Ubuntu 16+
# Origin Author:lmc999
# Dscription: Wireguard游戏加速器一键脚本
# Version: 2.0
# Github:https://github.com/lmc999/WireguardForGame
# TG交流群: https://t.me/gameaccelerate
# =========================================================

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo -e "${Blue}此脚本必须以root用户运行!即将退出程序...${Font}" 1>&2
       exit 1
    fi
}

checkos(){
    source /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
}




config_client(){
cat > /etc/wireguard/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24 
PreUp = start D:\software\TunSafe\bat\start.bat
PreUp = ping -n 4 127.1 >nul
PostUp = start D:\software\TunSafe\bat\routes-up.bat
PostDown = start D:\software\TunSafe\bat\routes-down.bat
PostDown = start D:\software\TunSafe\bat\stop.bat
DNS = 8.8.8.8
MTU = 1420
[Peer]
PublicKey = $s2
Endpoint = 127.0.0.1:2099
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25
EOF

}

#Install Wireguard
wireguard_install(){
    # Install WireGuard tools and module
	if [[ ${OS} == 'ubuntu' ]]; then
		apt-get update
		apt install linux-headers-$(uname -r)
		apt-get install -y wireguard iptables resolvconf qrencode
	elif [[ ${OS} == 'debian' ]]; then
		apt update
		apt install linux-headers-$(uname -r)
		apt install -y wireguard qrencode iptables resolvconf
	elif [[ ${OS} == 'centos' ]]; then
		yum update
		yum install epel-release elrepo-release -y
		yum install yum-plugin-elrepo -y
		yum install kmod-wireguard wireguard-tools iptables qrencode -y
		systemctl stop firewalld
		systemctl disable firewalld
	else
		echo -e "${Blue}此脚本暂不支持你的操作系统，即将退出...${Font}"
		exit 1
	
	fi
	
	# Configure Wireguard
	mkdir /etc/wireguard
    cd /etc/wireguard
    wg genkey | tee sprivatekey | wg pubkey > spublickey
    wg genkey | tee cprivatekey | wg pubkey > cpublickey
    s1=$(cat sprivatekey)
    s2=$(cat spublickey)
    c1=$(cat cprivatekey)
    c2=$(cat cpublickey)
    chmod 777 -R /etc/wireguard
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
    mkdir /etc/udp
    cd /etc/udp
	curl -o udp2raw https://raw.githubusercontent.com/lmc999/OpenvpnForGames/master/udp2raw
	curl -o speederv2 https://raw.githubusercontent.com/lmc999/OpenvpnForGames/master/speederv2
	chmod +x speederv2 udp2raw
	
	cat > /etc/wireguard/wg0.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24 
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $NIC -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $NIC -j MASQUERADE
ListenPort = 1195
DNS = 8.8.8.8
MTU = 1420
[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32
EOF

    config_client
    wg-quick up wg0
    systemctl enable wg-quick@wg0
}

# Configure auto start on boot
auto_start(){
    echo -e "${Green}正在配置加速程序开机自启${Font}"
    nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:1195 -f2:4 --mode 0 --timeout 2 >speeder.log 2>&1 &
	nohup ./udp2raw -s -l0.0.0.0:9898 -r 127.0.0.1:9999  --raw-mode faketcp  -a -k passwd >udp2raw.log 2>&1 &
    if [ "${OS}" == 'CentOS' ];then
        sed -i '/exit/d' /etc/rc.d/rc.local
        echo "nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:1195 -f2:4 --mode 0 --timeout 2 >speeder.log 2>&1 &
nohup ./udp2raw -s -l0.0.0.0:9898 -r 127.0.0.1:9999  --raw-mode faketcp  -a -k passwd >udp2raw.log 2>&1 & " >> /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
    elif [ -s /etc/rc.local ]; then
        sed -i '/exit/d' /etc/rc.local
        echo "nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:1195 -f2:4 --mode 0 --timeout 2 >speeder.log 2>&1 &
nohup ./udp2raw -s -l0.0.0.0:9898 -r 127.0.0.1:9999  --raw-mode faketcp  -a -k passwd >udp2raw.log 2>&1 & " >> /etc/rc.local
        chmod +x /etc/rc.local
    else
echo -e "${Green}检测到系统无rc.local自启，正在为其配置... ${Font} "
echo "[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/rc-local.service
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
" > /etc/rc.local
echo "nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:1195 -f2:4 --mode 0 --timeout 2 >speeder.log 2>&1 &
nohup ./udp2raw -s -l0.0.0.0:9898 -r 127.0.0.1:9999  --raw-mode faketcp  -a -k passwd >udp2raw.log 2>&1 & " >> /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1
systemctl start rc-local >/dev/null 2>&1
    fi
    sleep 3
    echo
    echo -e "${Blue}Wireguard游戏加速程序安装并配置成功!${Font}"    
    exit 0
}

rootness
checkos
wireguard_install
auto_start
