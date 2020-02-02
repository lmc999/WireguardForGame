@echo off
cd /d %~dp0
%1 start mshta vbscript:createobject("wscript.shell").run("""%~0"" ::",0)(window.close)&&exit

start /b udp2raw.exe -c -r44.55.66.77:9898 -l 127.0.0.1:9999 --raw-mode faketcp -k passwd
start /b speederv2.exe -c -l0.0.0.0:2099 -r127.0.0.1:9999 -f2:4 --mode 0 --report 10 --timeout 2



