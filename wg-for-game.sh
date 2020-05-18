#!/bin/bash

#判断系统
if [ ! -e '/etc/redhat-release' ]; then
echo "仅支持centos7"
exit
fi
if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
echo "仅支持centos7"
exit
fi



#更新内核
update_kernel(){

    sudo yum -y install epel-release
    sed -i "0,/enabled=0/s//enabled=1/" /etc/yum.repos.d/epel.repo
    yum remove -y kernel-devel
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
    yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
    yum -y --enablerepo=elrepo-kernel install kernel-ml
    sed -i "s/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/" /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
    wget http://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-devel-4.18.12-1.el7.elrepo.x86_64.rpm
    rpm -ivh kernel-ml-devel-4.18.12-1.el7.elrepo.x86_64.rpm
    yum -y --enablerepo=elrepo-kernel install kernel-ml-devel
    read -p "需要重启VPS，再次执行脚本选择安装wireguard，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
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

#centos7安装wireguard
wireguard_install(){
    sudo curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
    sudo yum install -y dkms gcc-c++ gcc-gfortran glibc-headers glibc-devel libquadmath-devel libtool systemtap systemtap-devel
    sudo yum -y install wireguard-tools
    mkdir /etc/wireguard
    cd /etc/wireguard
    wg genkey | tee sprivatekey | wg pubkey > spublickey
    wg genkey | tee cprivatekey | wg pubkey > cpublickey
    s1=$(cat sprivatekey)
    s2=$(cat spublickey)
    c1=$(cat cprivatekey)
    c2=$(cat cpublickey)
    chmod 777 -R /etc/wireguard
    systemctl stop firewalld
    systemctl disable firewalld
    yum install -y iptables-services 
    systemctl enable iptables 
    systemctl start iptables 
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    service iptables save
    service iptables restart
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
    mkdir /etc/udp
    cd /etc/udp
curl -o udp2raw https://raw.githubusercontent.com/lmc999/OpenvpnForGames/master/udp2raw
curl -o speederv2 https://raw.githubusercontent.com/lmc999/OpenvpnForGames/master/speederv2
chmod +x speederv2 udp2raw
nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:1195 -f2:4 --mode 0 --timeout 2 >speeder.log 2>&1 &
nohup ./udp2raw -s -l0.0.0.0:9898 -r 127.0.0.1:9999  --raw-mode faketcp  -a -k passwd >udp2raw.log 2>&1 &


cat > /etc/rc.d/init.d/udp<<-EOF
#!/bin/sh
#chkconfig: 2345 80 90
#description:udp
cd /etc/udp
nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:1195 -f2:4 --mode 0 --timeout 2 >speeder.log 2>&1 &
nohup ./udp2raw -s -l0.0.0.0:9898 -r 127.0.0.1:9999  --raw-mode faketcp  -a -k passwd >udp2raw.log 2>&1 &
EOF

chmod +x /etc/rc.d/init.d/udp
chkconfig --add udp
chkconfig udp on

cat > /etc/wireguard/wg0.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24 
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
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

#开始菜单
start_menu(){
    clear
    echo "1. 升级系统内核"
    echo "2. 安装wireguard+udpspeeder+udp2raw"
    echo "3. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    	1)
	update_kernel
	;;
	2)
	wireguard_install
	;;
	3)
	exit 1
	;;
	*)
	clear
	echo "请输入正确数字"
	sleep 5s
	start_menu
	;;
    esac
}

start_menu
