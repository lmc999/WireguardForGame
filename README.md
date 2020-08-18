![]( https://visitor-badge.glitch.me/badge?page_id=lmc999_wiregame)
# WireguardForGame

# 介绍

Wireguard走UDP协议，部分运营商会对UDP进行限速QOS处理使连接速度不理想或出现丢包情况。若串联udp2raw可将UDP流量伪装成TCP流量避免被运营商QOS。另外同时再串联udpspeeder多倍发包可降低游戏丢包率。本项目脚本会在服务器搭建Wireguard、udp2raw、udpspeeder服务，同时本地使用Tunsafe连接Wireguard时会自动运行大陆IP分流脚本，udp2raw和udpspeeder程序。

本项目脚本根据Atrandys一键脚本修改，请支持原作者，项目地址：https://github.com/atrandys/wireguard

# 事前准备

电脑需安装好winpcap或npcap，下载地址请自行百度。

目前脚本支持centos7+, debian8+, ubuntu16+

# 使用方法

> bash <(curl -L -s https://raw.githubusercontent.com/lmc999/WireguardForGame/master/wg-for-game.sh)

用Winscp等软件登入VPS,下载目录/etc/wireguard/中的client.conf到Tunsafe配置文件目录

下载Tunsafe用批处理文件文件[master.zip](https://github.com/lmc999/WireguardForGame/archive/master.zip)

解压缩文件，并将文件夹内的所有文件解压到 D:\software\TunSafe\bat

##### 本教程Tunsafe默认安装路径 D:\software\TunSafe,如果你的安装路径不一样请注意修改clien.conf中的批处理程序的路径.同时建议安装路径不要有空格。

用记事本打开start.bat，修改44.55.66.77为你Wireguard服务器ip

开启Tunsafe的Pre/Post命令功能。在"Option"选择"Allow Pre/Post Commands"

TunSafe选中client.conf, connect即可自动分流和串联udp2raw + udpspeeder

# Wireguard配合游戏规则使用

本项目搭建成功后默认是大陆白名单模式，可以直接进行游戏。

但同时Wireguard的Windows客户端Tunsafe支持添加路由规则，指定具体路由走wireguard代理，原理与SSTAP的游戏规则相同。使用方法是往Tunsafe配置文件中的AllowIPs参数添加游戏路由表。这里以PUBG亚服规则为例子，请参考[sample.conf](https://raw.githubusercontent.com/lmc999/WireguardForGame/master/sample.conf)

目前已有成熟的游戏规则项目，项目原本为SSTAP服务，但其实只需将该项目中的对应游戏规则添加到Wireguard中照样可正常使用。

项目传送门：https://github.com/FQrabbit/SSTap-Rule
