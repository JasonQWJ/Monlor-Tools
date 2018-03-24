#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

logsh "【Tools】" "获取版本更新脚本启动..."
logger -s -t "【Tools】" "获取更新插件列表"
rm -rf /tmp/applist.txt
[ "$model" == "arm" ] && applist="applist.txt"
[ "$model" == "mips" ] && applist="applist_mips.txt"
wgetsh $monlorpath/config/applist.txt $monlorurl/config/"$applist"
[ $? -ne 0 ] && logsh "【Tools】" "获取失败，检查网络问题！"

logger -s -t "【Tools】" "获取插件版本信息"
[ ! -d /tmp/version ] && mkdir -p /tmp/version
wgetsh /tmp/version/tools.txt $monlorurl/config/version.txt
[ $? -ne 0 ] && logsh "【Tools】" "获取工具箱版本信息失败！请稍后再试"
cat $monlorpath/config/applist.txt | while read line
do
	[ -z $line ] && continue
	wgetsh /tmp/version/$line.txt $monlorurl/apps/$line/config/version.txt
	if [ $? -ne 0 ]; then
		logsh "【Tools】" "获取【$line】版本号信息失败！请稍后再试"
	fi
done