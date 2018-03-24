#!/bin/ash
#copyright by monlor
logger -p 1 -t "【Tools】" "工具箱监测脚本启动..."
# logger -s -t "【Tools】" "监测脚本monitor.sh启动..."
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit
[ ! -d "$monlorpath" ] && logsh "【Tools】" "工具箱文件未找到，请确认是否拔出外接设备！" && exit

# [ ! -f "$monlorconf" ] && logsh "【Tools】" "找不到配置文件，工具箱异常！" && exit
result=$(ps | grep {monitor.sh} | grep -v grep | wc -l)
[ "$result" -gt '2' ] && logsh "【Tools】" "检测到monitor.sh已在运行" && exit
result1=$(ps | grep {monlor} | grep -v grep | wc -l)
result2=$(ps | grep {init.sh} | grep -v grep | wc -l)
[ "$result1" != '0' -a "$result2" == '0' ] && logsh "【Tools】" "检测到正在配置工具箱！" && exit

#检查samba共享目录
samba_path=$(uci -q get monlor.tools.samba_path)
if [ ! -z "$samba_path" ]; then
	logger -s -t "【Tools】" "检查samba共享目录配置"
	result=$(cat /etc/samba/smb.conf | grep -A 5 XiaoMi | grep -w $samba_path | awk '{print$3}')
	if [ "$result" != "$samba_path" ]; then
		logsh "【Tools】" "检测到samba路径被修改, 正在设置..."
		cp /etc/samba/smb.conf /tmp/smb.conf.bak
		sambaline=$(grep -A 1 -n "XiaoMi" /etc/samba/smb.conf | tail -1 | cut -d- -f1)
		[ ! -z "$sambaline" ] && sed -i ""$sambaline"s#.*#        path = $samba_path#" /etc/samba/smb.conf
		[ $? -ne 0 ] && mv /tmp/smb.conf.bak /etc/samba/smb.conf || rm -rf /tmp/smb.conf.bak
	fi
fi

#检查uci变更
if [ -f "/etc/config/monlor" ]; then
	[ ! -f $monlorpath/config/monlor.uci ] && touch $monlorpath/config/monlor.uci
	md5_1=$(md5sum /etc/config/monlor | cut -d' ' -f1)
	md5_2=$(md5sum $monlorpath/config/monlor.uci | cut -d' ' -f1)
	if [ "$md5_1" != "$md5_2" ]; then
		cp -rf /etc/config/monlor $monlorpath/config/monlor.uci
	fi
fi

#检查CPU占用100%问题
# result=$(top -n1 -b | grep ustackd | awk '{print$9}')
# if [ ! -z "$result" ]; then
# 	[ "$result" -gt "20" ] && killall ustackd > /dev/null 2>&1
# fi

monitor() {
	appname=$1
	checkuci $appname || return
	service=`uci -q get monlor.$1.service`
	if [ -z $appname ] || [ -z $service ]; then
		logsh "【Tools】" "uci配置出现问题！"
		return
	fi
	App_enable=$(uci -q get monlor.$appname.enable) 
	result=$($monlorpath/apps/$appname/script/$appname.sh status | tail -1) 
	process=$(ps | grep $monlorpath/apps/$appname/script/$appname.sh | grep -v grep | wc -l)
	
	#检查插件运行异常情况
	if [ "$process" == '0' ]; then
		if [ "$App_enable" == '1' -a "$result" == '0' ]; then
			logsh "【$service】" "$appname运行异常，正在重启..." 
			$monlorpath/apps/$appname/script/$appname.sh restart 
		elif [ "$App_enable" == '0' -a "$result" == '1' ]; then
			logsh "【$service】" "$appname配置已修改，正在停止$appname服务..."   
			$monlorpath/apps/$appname/script/$appname.sh stop
		fi
	fi

}

#监控运行状态
logger -s -t "【Tools】" "检查插件运行状态"
cat $monlorpath/config/applist.txt | while read line
do
	monitor $line
done
