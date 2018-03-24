#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=Aria2
appname=aria2
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
port=6800
BIN=$monlorpath/apps/$appname/bin/$appname
CONF=$monlorpath/apps/$appname/config/$appname.conf
LOG=/var/log/$appname.log
WEBDIR=$monlorpath/apps/$appname/web
port=$(uci -q get monlor.$appname.port) || port=6800
token=$(uci -q get monlor.$appname.token)
path=$(uci -q get monlor.$appname.path) || path="$userdisk/下载"

set_config() {

	logsh "【$service】" "加载$appname配置..."
	[ ! -f /etc/aria2.session ] && touch /etc/aria2.session

	sed -i "s/rpc-listen-port.*/rpc-listen-port=$port/" $CONF

	if [ ! -z "$token" ]; then
		sed -i "s/.*rpc-secret.*/rpc-secret=$token/" $CONF
	else
		sed -i "s/.*rpc-secret.*/#rpc-secret=/" $CONF
	fi

	sed -i "s#dir.*#dir=$path#" $CONF

	[ ! -d "$path" ] && mkdir -p $path

	if [ ! -d /www/$appname ]; then
		logsh "【$service】" "生成$appname本地web页面"
		ln -s $WEBDIR/AriaNG /www/$appname > /dev/null 2>&1
		[ $? -ne 0 ] && logsh "【$service】" "创建web页面失败，可能/www目录不可写入！"
	fi

}

start () {

	result=$(ps | grep $BIN | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "

	set_config
	
	iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	service_start $BIN --conf-path=$CONF -D -l $LOG
	if [ $? -ne 0 ]; then
        	logsh "【$service】" "启动$appname服务失败！"
		exit
	fi
	logsh "【$service】" "启动$appname服务完成！"
	logsh "【$service】" "访问[http://$lanip/$appname]管理服务"
	[ -z "$token" ] && tokentext="" || tokentext=token:"$token"@
	logsh "【$service】" "jsonrpc地址:http://"$tokentext""$lanip":"$port"/jsonrpc"

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	service_stop $BIN
	ps | grep $BIN | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
	[ -d /www/$appname ] && rm -rf /www/$appname

}

restart () {

	stop
	sleep 1
	start

}

status() {

	result=$(ps | grep $BIN | grep -v grep | wc -l)
	if [ "$result" == '0' ]; then
		echo "未运行"
		echo "0"
	else
		[ ! -z $user ] && flag1=", 用户名: $user"
		flag2=", 下载路径: $path"
		echo "运行端口号: $port$flag1$flag2"
		echo "1"
	fi

}

backup() {

	mkdir -p $monlorbackup/$appname
	cp -rf $CONF $monlorbackup/$appname/$appname.conf

}

recover() {

	cp -rf $monlorbackup/$appname/$appname.conf $CONF

}