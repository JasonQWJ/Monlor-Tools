#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=Frpc
appname=frpc
uciname=info
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
# port=
BIN=$monlorpath/apps/$appname/bin/$appname
CONF=$monlorpath/apps/$appname/config/$appname.conf
LOG=/var/log/$appname.log
server=$(uci -q get monlor.$appname.server)
server_port=$(uci -q get monlor.$appname.server_port)

set_config() {

	logsh "【$service】" "生成$appname配置文件"
	result=$(uci -q show monlor.$appname | grep server | wc -l)
	if [ "$result" == '0' ]; then
		logsh "【$service】" "$appname配置出现问题！"
		exit
	fi
	
	token=$(uci -q get monlor.$appname.token)
	cat > $CONF <<-EOF
	[common]
	server_addr = $server
	server_port = $server_port
	privilege_token = $token
	log_file = $LOG
	log_level = info
	log_max_days = 1
	EOF
	ucish keys | while read line
	do
		[ -z "$line" ] || [ ${line:0:1} == "#" ] && continue
		echo >> $CONF
		name="$line"
		info=$(ucish get $name)
		echo "[$name]" >> $CONF
		type=`cutsh $info 1`
		[ "$type" != "http" -a "$type" != "tcp" ] &&  logsh "【$service】" "节点$name类型设置错误！" && exit
		echo "type = $type" >> $CONF
		echo "local_ip = `cutsh $info 2`" >> $CONF
		echo "local_port = `cutsh $info 3`" >> $CONF
		if [ "$type" == "tcp" -o "$type" == "udp" ]; then
			echo "remote_port = `cutsh $info 4`" >> $CONF
			logsh "【$service】" "加载$appname配置:【$name】启动为tcp/udp模式,端口号:[`cutsh $line 5`]"
		fi
		if [ "$type" == "http" -o "$type" == "https" ]; then
			domain=`cutsh $info 5`
			if [ `echo $domain | grep "\." | wc -l` -eq 0 ]; then
				echo "subdomain = $domain" >> $CONF
				logsh "【$service】" "加载$appname配置:【$name】启动为http/https子域名模式,域名:[$domain]"
			else
				echo "custom_domain = $domain" >> $CONF
				logsh "【$service】" "加载$appname配置:【$name】启动为http/https自定义域名模式,域名:[$domain]"
			fi
		fi
		echo "use_encryption = true" >> $CONF
		echo "use_gzip = false" >> $CONF
	done

}

start () {

	result=$(ps | grep $BIN | grep -v grep | wc -l)
   	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "

	set_config
	
	# iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	service_start $BIN -c $CONF
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动$appname服务失败！"
		exit
    fi
    logsh "【$service】" "启动$appname服务完成！"

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	service_stop $BIN
	ps | grep $BIN | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	# iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
	rm -rf $CONF > /dev/null 2>&1

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
		echo "运行服务器: $server:$server_port"
		echo "1"
	fi

}

backup() {

	mkdir -p $monlorbackup/$appname

}

recover() {

	echo -n

}