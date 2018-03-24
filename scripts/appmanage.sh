#!/bin/ash
#copyright by monlor
logger -p 1 -t "【Tools】" "插件管理脚本appmanage.sh启动..."
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

[ -z "$1" -o -z "$2" ] && echo "Usage: $0 {add|upgrade|del} appname" && exit
addtype=`echo $2 | grep -E "/|\." | wc -l`
apppath=$(dirname $2) 
appname=$(basename $2 | cut -d'.' -f1) 
[ "$3" == "-f" ] && force=1 || force=0
[ -z "`uci -q get monlor.tools`" ] && logsh "【Tools】" "工具箱配置文件未创建！" && exit

getapp() {

	[ "$force" == '0' ] && checkuci $appname && logsh "【Tools】" "插件【$appname】已经安装！" && exit
	if [ "$addtype" == '0' ]; then #检查是否安装在线插件
		#下载插件
		logsh "【Tools】" "以在线的方式安装插件..."
		logsh "【Tools】" "下载【$appname】安装文件"
		wgetsh "/tmp/$appname.tar.gz" "$monlorurl/appstore/$appname.tar.gz"
		if [ $? -eq 1 ]; then
			logsh "【Tools】" "文件下载失败！"
			exit
		fi
	else
		logsh "【Tools】" "以离线的方式安装插件..."
		[ ! -f "$apppath/$appname.tar.gz" ] && logsh "【Tools】" "未找到离线安装包" && exit
		cp $apppath/$appname.tar.gz /tmp > /dev/null 2>&1
	fi
	logsh "【Tools】" "解压安装文件"
	tar -zxvf /tmp/$appname.tar.gz -C /tmp > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		logsh "【Tools】" "文件解压失败！" 
		exit
	fi

}

add() {

	if [ -d /tmp/$appname/bin ]; then
		if [ "$model" == "arm" ]; then
			rm -rf /tmp/$appname/bin/*_*
		elif [ "$model" == "mips" ]; then
			ls /tmp/$appname/bin | grep -v ".*_.*" | while read line
			do
				rm -rf /tmp/$appname/bin/"$line"
				#是文件夹
				[ -d /tmp/$appname/bin/$line ] && continue
				#判断特定型号
				if [ -f /tmp/$appname/bin/"$line"_"$xq" ]; then
					mv -f /tmp/$appname/bin/"$line"_"$xq" /tmp/$appname/bin/"$line"
				else
					#判断是否有mips文件
					[ -f /tmp/$appname/bin/"$line"_mips ] && mv -f /tmp/$appname/bin/"$line"_mips /tmp/$appname/bin/"$line"
				fi
				rm -rf /tmp/$appname/bin/"$line"_*
			done
		else 
			logsh "【Tools】" "不支持你的路由器！"
			exit
		fi
	fi
	
	#检查applist是否存在插件
	result=$(cat $monlorpath/config/applist.txt | grep -c "^$appname$")
	if [ "$result" == '0' ]; then
		[ -f $monlorpath/config/applist_extra.txt ] && touch $monlorpath/config/applist_extra.txt
		result=$(cat $monlorpath/config/applist_extra.txt | grep -c "^$appname$")
		[ "$result" == '0' ] && echo "$appname" >> $monlorpath/config/applist_extra.txt
	fi

	logsh "【Tools】" "初始化uci配置"
	#初始化uci配置	
	uci set monlor.$appname=config
	#每天定时重启
	echo " [ \`uci get monlor.$appname.enable\` -eq 1 ] && $monlorpath/apps/$appname/script/$appname.sh restart" >> $monlorpath/scripts/dayjob.sh
	#添加版本信息
	[ ! -d /tmp/version ] && mkdir -p /tmp/version
	cp -rf /tmp/$appname/config/version.txt /tmp/version/$appname.txt
	#赋予可执行权限
	chmod +x -R /tmp/$appname/
	#运行安装脚本
	if [ -f /tmp/$appname/install/install.sh ]; then
		logsh "【Tools】" "运行插件安装脚本"
		/tmp/$appname/install/install.sh
	fi
	#安装插件
	logsh "【Tools】" "安装插件到工具箱"
	rm -rf /tmp/$appname/install
	cp -rf /tmp/$appname $monlorpath/apps
	#清除临时文件
	rm -rf /tmp/$appname
	rm -rf /tmp/$appname.tar.gz
	logsh "【Tools】" "插件【$appname】安装完成"
 
}

upgrade() {
	
	[ "$force" == '0' ] && !(checkuci $appname) && logsh "【Tools】" "插件【$appname】未安装！" && exit
	if [ "$force" == '0' ]; then 
		#检查更新
		rm -rf /tmp/version.txt
		wgetsh "/tmp/version.txt" "$monlorurl/apps/$appname/config/version.txt"
		[ $? -ne 0 ] && logsh "【Tools】" "检查更新失败！" && exit
		newver=$(cat /tmp/version.txt)
		oldver=$(cat $monlorpath/apps/$appname/config/version.txt) > /dev/null 2>&1
		[ $? -ne 0 ] && logsh "【Tools】" "$appname文件出现问题，请卸载后重新安装" && exit
		logsh "【Tools】" "当前版本$oldver，最新版本$newver"
		!(compare $newver $oldver) && logsh "【Tools】" "【$appname】已经是最新版！" && exit
		logsh "【Tools】" "版本不一致，正在更新【$appname】插件... "
	fi
	#停止插件
	$monlorpath/apps/$appname/script/$appname.sh stop > /dev/null 2>&1
	#先获取插件包
	force=1 && getapp
	#删除插件的配置
	logsh "【Tools】" "清除一些旧的配置..."
	sed -i "/script\/$appname/d" $monlorpath/scripts/dayjob.sh
	#安装服务
	add $appname
	# logsh "【Tools】" "插件【$appname】更新完成"
	# result=$(uci -q get monlor.$appname.enable)
	# if [ "$result" == '1' ]; then
	# 	logsh "【Tools】" "正在启动【$appname】服务"
	# 	$monlorpath/apps/$appname/script/$appname.sh start
	# fi
}

del() {

	if !(checkuci $appname) && [ "$force" == '0' ]; then
		echo -n "【$appname】插件未安装！继续卸载？[y/n] "
		read answer
		[ "$answer" == "n" ] && exit
	fi
	$monlorpath/apps/$appname/script/$appname.sh stop > /dev/null 2>&1
	#删除插件的配置
	logsh "【Tools】" "正在卸载【$appname】插件..."
	uci -q del monlor.$appname
	uci commit monlor
	# 清除非工具箱自带插件的list
	if [ -f $monlorpath/config/applist_extra.txt ]; then
		result=$(cat $monlorpath/config/applist_extra.txt | grep -c "^$appname$")
		if [ "$result" != '0' ]; then
			sed -i "/^$appname$/d" $monlorpath/config/applist_extra.txt
		fi
	fi
	rm -rf $monlorpath/apps/$appname > /dev/null 2>&1
	sed -i "/script\/$appname/d" $monlorpath/scripts/dayjob.sh
	# install_line=`cat $monlorconf | grep -n install_$appname | cut -d: -f1`           
 	# [ ! -z "$install_line" ] && sed -i ""$install_line"s/1/0/" $monlorconf 
        logsh "【Tools】" "插件【$appname】卸载完成"

}
 

case $1 in
	add) getapp && add ;;
	upgrade) upgrade ;;
	del) del ;;
	*) echo "Usage: $0 {add|upgrade|del} appname"
esac
