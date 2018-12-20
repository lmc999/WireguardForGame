# WireguardForGame

# 介绍

Wireguard走UDP协议，部分运营商会对UDP进行限速QOS处理使连接速度不理想或出现丢包情况。若串联udp2raw可将UDP流量伪装成TCP流量避免被运营商QOS。本项目脚本会在服务器搭建Wireguard和udp2raw服务，同时本地使用Tunsafe连接Wireguard时会自动运行大陆IP分流脚本和udp2raw程序。

本项目脚本根据Atrandys一键脚本修改，请支持原作者，项目地址：https://github.com/yobabyshark/wireguard

# 使用方法

> bash <(curl -L -s https://raw.githubusercontent.com/lmc999/WireguardForGame/master/wgforgame.sh)

用Winscp等软件登入VPS,下载目录/etc/wireguard/中的client.conf到Tunsafe配置文件目录

下载Tunsafe用批处理文件文件： https://github.com/lmc999/Wireguard-anti-QOS/archive/master.zip

解压缩文件，并将文件夹内的所有文件解压到 D:\software\TunSafe\bat

##### 本教程Tunsafe默认安装路径 D:\software\TunSafe,如果你的安装路径不一样请注意修改clien.conf中的批处理程序的路径.同时建议安装路径不要有空格。

用记事本打开start.bat，修改44.55.66.77为你Wireguard服务器ip

开启Tunsafe的Pre/Post命令功能。在"Option"选择"Allow Pre/Post Commands"

TunSafe选中client.conf, connect即可自动分流和串联udp2raw
