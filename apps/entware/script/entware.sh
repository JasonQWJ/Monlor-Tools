#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=Entware
appname=entware
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
# port=
BIN=/opt/etc/init.d/rc.unslung
# CONF=$monlorpath/apps/$appname/config/$appname.conf
LOG=/var/log/$appname.log
path=$(uci -q get monlor.$appname.path) || path="$userdisk/.Entware"

install() {

	logsh "【$service】" "安装$appname服务"
	if [ -z "$path" ]; then 
		logsh "【$service】" "未配置安装路径！" 
		exit
	fi
	[ ! -f $BIN ] && mount -o blind $path /opt > /dev/null 2>&1
	result=$(cat /etc/profile | grep "/opt/sbin" | wc -l)
	[ "$result" == '0' ] && sed -i "s/export PATH=/export PATH=\/opt\/bin:\/opt\/sbin:/" /etc/profile
	result1=$(cat /etc/profile | grep -c "/opt/lib")
	result2=$(cat /etc/profile | grep -c "LD_LIBRARY_PATH")
	if [ "$result1" == '0' ]; then
		if [ "$result2" == '0' ]; then
			echo "export LD_LIBRARY_PATH=/usr/lib:/lib:/opt/lib" >> /etc/profile
		else
			sed -i "s#/usr/lib:/lib#/usr/lib:/lib:/opt/lib#" /etc/profile
		fi
		source /etc/profile > /dev/null 2>&1
	fi
	
	if [ ! -f $path/etc/init.d/rc.unslung ]; then
		logsh "【$service】" "检测到第一次运行$appname服务，正在安装..."
		mkdir -p $path > /dev/null 2>&1
		[ $? -ne 0 ] && logsh "【Tools】" "创建目录失败，检查你的路径是否正确！" && exit
		umount -lf /opt > /dev/null 2>&1
		mount -o blind $path /opt
		if [ "$model" == "arm" ]; then
			wget -O - http://pkg.entware.net/binaries/armv7/installer/entware_install.sh | sh
		elif [ "$model" == "mips" ]; then
			wget -O - http://pkg.entware.net/binaries/mipsel/installer/installer.sh | sh
		else
			logsh "【Tools】" "不支持你的路由器！"
			exit
		fi
		if [ $? -ne 0 ]; then
			logsh "【Tools】" "【$appname】服务安装失败"
			umount -lf /opt
			rm -rf $path
		fi
		source /etc/profile > /dev/null 2>&1
		logsh "【$service】" "安装完成，请运行source /etc/profile使配置生效!"
	fi
}

start () {

	result=$(ps | grep "{$appname}" | grep -v grep | wc -l)
    	if [ "$result" -gt '2' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "

	install
	
	# iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	[ ! -f "$BIN" ] && sleep 2
	$BIN start >> /tmp/messages 2>&1
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动$appname服务失败！"
		exit
    else
    	logsh "【$service】" "$appname服务启动完成"
    fi

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	$BIN stop >> /tmp/messages 2>&1
	[ -f $BIN ] && umount -lf /opt
	umount -lf /lib > /dev/null 2>&1
	result=$(cat /etc/profile | grep -c "/opt/lib")
	[ "$result" != '0' ] && sed -i "s/:\/opt\/lib//" /etc/profile
	result=$(cat /etc/profile | grep -c /opt/sbin)
	[ "$result" != '0' ] && sed -i "s/\/opt\/bin:\/opt\/sbin://" /etc/profile
	# ps | grep $BIN | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	# iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
	logsh "【$service】" "停止成功，请运行source /etc/profile使配置生效!"
	logsh "【$service】" "若要重置【$appname】服务，删除$path文件并启动即可"

}

restart () {

	stop
	sleep 1
	start

}

status() {

	result1=$(cat /etc/profile | grep -c "/opt/lib")
	result2=$(cat /etc/profile | grep -c /opt/sbin)
	if [ ! -f $BIN ] || [ -z $path ] || [ "$result1" == '0' ] || [ "$result2" == '0' ]; then
		echo "未运行"
		echo "0"
	else
		echo "安装路径: $path"
		echo "1"
	fi

}

backup() {

	mkdir -p $monlorbackup/$appname
	echo -n
}

recover() {

	echo -n
}