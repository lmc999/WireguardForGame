@ECHO OFF 
%1 start mshta vbscript:createobject("wscript.shell").run("""%~0"" ::",0)(window.close)&&exit

taskkill /im speederv2.exe /f
taskkill /im udp2raw.exe /f

ping -n 2 127.1 >nul