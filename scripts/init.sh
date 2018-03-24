#!/bin/ash
#copyright by monlor
logger -p 1 -t "【Tools】" "工具箱初始化脚本启动..."
monlorpath=$(uci -q get monlor.tools.path)
userdisk=$(uci -q get monlor.tools.userdisk)
if [ -z "$monlorpath" ] || [ -z "$userdisk" ]; then
	model=$(cat /proc/xiaoqiang/model)
	if [ "$model" == "R1D" -o "$model" == "R2D" -o "$model" == "R3D"  ]; then
		userdisk="/userdisk/data"
		monlorpath="/etc/monlor"
	elif [ "$model" == "R3" -o "$model" == "R3P" -o "$model" == "R3G" -o "$model" == "R1CM" ]; then
		if [ $(df|grep -Ec '\/extdisks\/sd[a-z][0-9]?$') -ne 0 ]; then
			userdisk=$(df|awk '/\/extdisks\/sd[a-z][0-9]?$/{print $6;exit}')
			if [ -d "/etc/monlor" ]; then
				monlorpath="/etc/monlor"
			else
				monlorpath=$userdisk/.monlor
			fi
		else
			userdisk="/etc/monlor"
			monlorpath="/etc/monlor"
		fi
	fi
	if [ ! -f /etc/config/monlor ]; then
		cp -rf "$monlorpath"/config/monlor.uci /etc/config/monlor 
	fi
	uci set monlor.tools.userdisk="$userdisk"
	uci set monlor.tools.path="$monlorpath"
	uci commit monlor
fi
[ ! -d "$monlorpath" ] && logger -s -p 1 -t "【Tools】" "未找到工具箱文件！" && exit

source "$monlorpath"/scripts/base.sh || exit

mount -o remount,rw /

result=`ps | grep init.sh | grep -v grep | wc -l`
if [ "$result" -gt '2' ]; then
        logsh "【Tools】" "检测到初始化脚本已在运行"
        exit
fi

logsh "【Tools】" "检查环境变量配置"
result=$(cat /etc/profile | grep monlor | wc -l)
if [ "$result" == 0 ]; then
	sed -i "s#:$monlorpath/scripts##" /etc/profile
	sed -i "s#/usr/sbin#/usr/sbin:$monlorpath/scripts#" /etc/profile
fi

# 解决小米路由器top命令使用问题
result=$(cat /etc/profile | grep -c TERM)
[ "$result" == '0' ] && echo "export TERM=xterm #monlor-tools" >> /etc/profile

logsh "【Tools】" "检查定时任务配置"
cru a monitor "* * * * * $monlorpath/scripts/monitor.sh "
cru a dayjob "30 5 * * * $monlorpath/scripts/dayjob.sh " 
cru a getver "*/20 * * * * $monlorpath/scripts/getver.sh"

logsh "【Tools】" "检查工具箱开机启动配置"
result=$(cat /etc/firewall.user | grep init.sh | wc -l) > /dev/null 2>&1
if [ "$result" == '0' ]; then
	echo "$monlorpath/scripts/init.sh" > /etc/firewall.user
fi

result1=$(uci -q get monlor.tools.hosts)
if [ "$result1" == '1' ]; then
	logsh "【Tools】" "检查GitHub的hosts配置"
	result2=$(cat /etc/hosts | grep -c "monlor-hosts")
	if [ "$result2" == '0' ]; then
		cat $monlorpath/config/hosts.txt >> /etc/hosts
	fi
fi


logsh "【Tools】" "运行工具箱监控脚本"
$monlorpath/scripts/monitor.sh

logsh "【Tools】" "获取工具箱版本信息"
$monlorpath/scripts/getver.sh

xunlei_disable=$(uci -q get monlor.tools.xunlei)
if [ "$xunlei_disable" == '1' ]; then
	logsh "【Tools】" "检查迅雷配置"
	xunlei_enabled=$(ps | grep -E 'etm|xunlei' | grep -v grep | wc -l)
	if [ "$xunlei_enabled" != '0' ]; then
		[ -f /usr/sbin/xunlei.sh ] && mv /usr/sbin/xunlei.sh /usr/sbin/xunlei.sh.bak
		killall xunlei > /dev/null 2>&1
		killall etm > /dev/null 2>&1
		/etc/init.d/xunlei stop &
	fi
fi

logsh "【Tools】" "检查ssh外网访问配置"
ssh_enabled=$(iptables -S | grep -c "monlor-ssh")
if [ "$ssh_enabled" == '0' ]; then
	iptables -I INPUT -p tcp --dport 22 -m comment --comment "monlor-ssh" -j ACCEPT > /dev/null 2>&1
fi

# 禁止更新
no_update=$(uci -q get monlor.tools.no_update)
if [ "$no_update" == '1' ]; then
	sed -i "/otapredownload/d" /etc/crontabs/root
else
	sed -i "/otapredownload/d" /etc/crontabs/root
	echo "15 3,4,5 * * * /usr/sbin/otapredownload >/dev/null 2>&1" >> /etc/crontabs/root
fi

logsh "【Tools】" "运行用户自定义脚本"
$monlorpath/scripts/userscript.sh

