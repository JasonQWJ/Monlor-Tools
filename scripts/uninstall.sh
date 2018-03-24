#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

clear
logsh "【Tools】" "即将卸载工具箱，按任意键继续(Ctrl + C 退出)."
read answer

logsh "【Tools】" "正在卸载工具箱..."

logsh "【Tools】" "停止所有插件"

ls $monlorpath/apps | while read line
do
	result=$(uci -q get monlor.$line.enable)
	[ "$result" == '1' ] && $monlorpath/apps/$line/script/$line.sh stop
done

logsh "【Tools】" "删除所有工具箱配置信息"

result=$(cat /etc/profile | grep monlor | wc -l)
if [ "$result" != 0 ]; then
	sed -i "s#:$monlorpath/scripts##" /etc/profile
	sed -i "/LD_LIBRARY_PATH/d" /etc/profile
fi

# 清除添加的环境变量
sed -i "/#monlor-tools/d" /etc/profile

logsh "【Tools】" "删除定时任务"
cru c

result=$(cat /etc/firewall.user | grep init.sh | wc -l) > /dev/null 2>&1
if [ "$result" != '0' ]; then
	sed -i "/init.sh/d" /etc/firewall.user
fi

# if [ -f "$monlorconf" ]; then
# 	mv $monlorconf $userdisk/.monlor.conf.bak
# fi

xunlei_enable=$(uci -q get monlor.tools.xunlei)
if [ "$xunlei_enable" == '1' ]; then
	logsh "【Tools】" "检测到迅雷被关闭，正在恢复，重启后生效"
	[ ! -f /usr/sbin/xunlei.sh ] && mv /usr/sbin/xunlei.sh.bak /usr/sbin/xunlei.sh
fi

if [ -f "/etc/config/monlor" ]; then
	rm -rf /etc/config/monlor
fi

logsh "【Tools】" "See You!"

rm -rf $monlorpath
