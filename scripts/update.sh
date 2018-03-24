#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

logsh "【Tools】" "正在更新工具箱程序... "
command -v wgetsh > /dev/null 2>&1
wgetenable="$?"
if [ "$1" != "-f" ]; then
	#检查更新
	if [ "$wgetenable" -ne 0 ]; then
		logsh "【Tools】" "使用临时的下载方式"
		result=$(curl -skL -w %{http_code} -o /tmp/tools.txt $monlorurl/config/version.txt)
	 	[ "$result" != "200" ] && logsh "【Tools】" "检查更新失败！" && exit
	else
		wgetsh /tmp/version/tools.txt $monlorurl/config/version.txt > /dev/null 2>&1
		[ $? -ne 0 ] && logsh "【Tools】" "检查更新失败！" && exit
	fi
	newver=$(cat /tmp/version/tools.txt)
	oldver=$(cat $monlorpath/config/version.txt)
	logsh "【Tools】" "当前版本$oldver，最新版本$newver"
	command -v compare > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		compare $newver $oldver || logsh "【Tools】" "工具箱已经是最新版！" && exit
	else
		[ "$newver" == "$oldver" ] && logsh "【Tools】" "工具箱已经是最新版！" && exit
	fi
	logsh "【Tools】" "版本不一致，正在更新工具箱..."
fi
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor
if [ "$wgetenable" -ne 0 ]; then
	logsh "【Tools】" "使用临时的下载方式"
	result=$(curl -skL -w %{http_code} -o "/tmp/monlor.tar.gz" "$monlorurl/appstore/monlor.tar.gz")
	[ "$result" != "200" ] && logsh "【Tools】" "工具箱文件下载失败！"  && exit
else 
	wgetsh "/tmp/monlor.tar.gz" "$monlorurl/appstore/monlor.tar.gz" > /dev/null 2>&1
	[ $? -ne 0 ] && logsh "【Tools】" "工具箱文件下载失败！"  && exit
fi
logsh "【Tools】" "解压工具箱文件"
tar -zxvf /tmp/monlor.tar.gz -C /tmp > /dev/null 2>&1
[ $? -ne 0 ] && logsh "【Tools】" "文件解压失败！" && exit
logsh "【Tools】" "更新工具箱配置脚本"
# 清除更新时不需要的文件
rm -rf /tmp/monlor/apps
rm -rf /tmp/monlor/scripts/dayjob.sh
rm -rf /tmp/monlor/config/monlor.uci
rm -rf /tmp/monlor/scripts/userscript.sh
[ "$model" == "arm" ] && rm -rf /tmp/monlor/config/applist_mips.txt
[ "$model" == "mips" ] && mv -f /tmp/monlor/config/applist_mips.txt /tmp/monlor/config/applist.txt
# 更新版本号(因为强制更新跳过版本号检查不会更新版本号)
cp -rf /tmp/monlor/config/version.txt /tmp/version/tools.txt
logsh "【Tools】" "更新工具箱文件"
cp -rf /tmp/monlor/* $monlorpath/
logsh "【Tools】" "赋予可执行权限"
chmod -R +x $monlorpath/scripts/*
chmod -R +x $monlorpath/config/*

#删除临时文件
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor

#旧版本处理
result=$(cat /etc/crontabs/root	| grep -c "#monlor-cru")
if [ "$result" == '0' ]; then
	sed -i "/monlor/d" /etc/crontabs/root	
	$monlorpath/scripts/init.sh
fi
[ -f $monlorpath/scripts/crontab.sh ] && rm -rf $monlorpath/scripts/crontab.sh
[ -f $monlorpath/scripts/wget.sh ] && rm -rf $monlorpath/scripts/wget.sh
[ -f $monlorpath/scripts/cru ] && rm -rf $monlorpath/scripts/cru
[ -f $monlorpath/config/cru.conf ] && rm -rf $monlorpath/config/cru.conf

cat $monlorpath/config/applist* | while read line
do
	checkuci $line || continue
	[ -f $monlorpath/apps/$line/config/monlor.conf ] && break
	wgetsh $monlorpath/apps/$line/config/monlor.conf $monlorurl/apps/$line/config/monlor.conf
done

logsh "【Tools】" "工具箱更新完成！"