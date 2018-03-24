#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

[ -d $monlorpath/apps/$appname/lib ] && rm -rf $monlorpath/apps/$appname/lib