#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit
appname=shadowsocks
service=ShadowSocks
chnroute=$monlorpath/apps/$appname/config/chnroute.conf
gfwlist=$monlorpath/apps/$appname/config/gfwlist.conf

logsh "【$service】" "更新$appname分流规则"
wgetsh $gfwlist https://cokebar.github.io/gfwlist2dnsmasq/gfwlist_domain.txt
[ $? -ne 0 ] && logsh "【$service】" "更新gfw黑名单规则失败"
wgetsh $chnroute https://koolshare.ngrok.wang/maintain_files/chnroute.txt
[ $? -ne 0 ] && logsh "【$service】" "更新大陆白名单规则失败"