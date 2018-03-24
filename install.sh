#!/bin/ash
#copyright by monlor

clear
logsh() {
	# 输出信息到/tmp/messages和标准输出
	logger -s -p 1 -t "$1" "$2"
	return 0
	
}
echo "***********************************************"
echo "**                                           **"
echo "**          Welcome to Monlor Tools!         **"
echo "**                                           **"
echo "***********************************************"
logsh "【Tools】" "请按任意键安装工具箱(Ctrl + C 退出)."
read answer
monlorurl="https://coding.net/u/monlor/p/Monlor-Tools/git/raw/master"
model=$(cat /proc/xiaoqiang/model)
if [ "$model" == "R1D" -o "$model" == "R2D" -o "$model" == "R3D"  ]; then
	userdisk="/userdisk/data"
	monlorpath="/etc/monlor"
	CPU=arm
elif [ "$model" == "R3" -o "$model" == "R3P" -o "$model" == "R3G" -o "$model" == "R1CM" ]; then
	if [ $(df|grep -Ec '\/extdisks\/sd[a-z][0-9]?$') -ne 0 ]; then
		userdisk=$(df|awk '/\/extdisks\/sd[a-z][0-9]?$/{print $6;exit}')
		logsh "【Tools】" "请选择安装路径(1.内置储存 2.外置储存) " 
		read res
		if [ "$res" == '1' ]; then
			monlorpath="/etc/monlor"
		elif [ "$res" == '2' ]; then
			monlorpath=$userdisk/.monlor
		else
			logsh "【Tools】" "输入有误！"
			exit
		fi
	else
		logsh "【Tools】" "未检测到外置储存，确定要安装到内置储存？[1/0] " 
		read res
		[ "$res" == '0' ] && exit
		userdisk="/etc/monlor"
		monlorpath="/etc/monlor"
	fi
	CPU=mips
else
	logsh "【Tools】" "不支持你的路由器！"
	exit
fi

if [ -d "$monlorpath" ]; then
	logsh "【Tools】" "工具箱已安装，是否覆盖？[1/0] " 
	read res
	if [ "$res" == '1' ]; then
		rm -rf $monlorpath 
		rm -rf /etc/config/monlor
	else
		exit
	fi
fi
mount -o remount,rw /
logsh "【Tools】" "下载工具箱文件..."
rm -rf /tmp/monlor.tar.gz > /dev/null 2>&1
curl -skLo /tmp/monlor.tar.gz "$monlorurl"/appstore/monlor.tar.gz
[ $? -ne 0 ] && logsh "【Tools】" "文件下载失败！" && exit
logsh "【Tools】" "解压工具箱文件"
tar -zxvf /tmp/monlor.tar.gz -C /tmp > /dev/null 2>&1
[ $? -ne 0 ] && logsh "【Tools】" "文件解压失败！" && exit
# 清楚不需要的文件
[ "$CPU" == "arm" ] && rm -rf /tmp/monlor/config/applist_mips.txt
[ "$CPU" == "mips" ] && mv -f /tmp/monlor/config/applist_mips.txt /tmp/monlor/config/applist.txt

cp -rf /tmp/monlor $monlorpath
chmod -R +x $monlorpath/*
logsh "【Tools】" "初始化工具箱..."
[ ! -f "/etc/config/monlor" ] && touch /etc/config/monlor
uci set monlor.tools=config
uci set monlor.tools.userdisk="$userdisk"
uci set monlor.tools.path="$monlorpath"
uci set monlor.tools.url="$monlorurl"
uci commit monlor

# if [ -f "$userdisk/.monlor.conf.bak" ]; then
# 	echo -n "检测到备份的配置，是否要恢复？[y/n] "
# 	read answer
# 	if [ "$answer" == 'y' ]; then
# 		mv $userdisk/.monlor.conf.bak $userdisk/.monlor.conf
# 	else
# 		[ ! -f $userdisk/.monlor.conf ] && cp /etc/monlor/config/monlor.conf $userdisk/.monlor.conf
# 	fi
# fi
kill -9 $(echo $(ps | grep monlor/scripts | grep -v grep | awk '{print$1}')) > /dev/null 2>&1
$monlorpath/scripts/init.sh
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor
logsh "【Tools】" "工具箱安装完成!"

logsh "【Tools】" "运行monlor命令即可配置工具箱"
rm -rf /tmp/install.sh
