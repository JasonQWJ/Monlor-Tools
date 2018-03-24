#!/bin/bash
path=~/Documents/Monlor-Tools
cd $path
[ $? -ne 0 ] && echo "Change directory failed!" && exit
#find  .  -name  '._*'  -type  f  -print  -exec  rm  -rf  {} \;
find . -name '.DS_Store' | xargs rm -rf
find . -name '._*' | xargs rm -rf
if [ "`uname -s`" == "Darwin" ]; then
	md5=md5 
else 
	md5=md5sum
fi

vtools() {
	version=$(cat config/version.txt)
	num1=$(echo "$version" | cut -d'.' -f1)
	num2=$(echo "$version" | cut -d'.' -f2)
	num3=$(echo "$version" | cut -d'.' -f3)
	num4=$(echo "$version" | cut -d'.' -f4)
	oldver="$num1"."$num2"."$num3"
	newver="$num1"."`date +%-m.%-d`"
	if [ "$newver" == "$oldver" ]; then
		[ -z "$num4" ] && num4=1 || let num4=$num4+1
		echo "$newver"."$num4" > config/version.txt
	else
		echo "$newver" > config/version.txt
	fi
}

vapp() {
	local appname="$1"
	version=$(cat $appname/config/version.txt)
	num1=$(echo "$version" | cut -d'.' -f1)
	num2=$(echo "$version" | cut -d'.' -f2)
	num3=$(echo "$version" | cut -d'.' -f3)
	let num3=$num3+1
	echo "$num1.$num2.$num3" > $appname/config/version.txt
}

pack() {
	rm -rf monlor/
	rm -rf monlor.tar.gz
	mkdir -p monlor/apps/
	cp -rf config/ monlor/config
	cp -rf scripts/ monlor/scripts
	#test
	# cp install.sh install_test.sh
	# if [ "`uname -s`" == "Darwin" ]; then
	# 	sed -i "" 's/Monlor-Tools/Monlor-Test/' install_test.sh
	# else 
	# 	sed -i 's/Monlor-Tools/Monlor-Test/' install_test.sh
	# fi
	tar -zcvf monlor.tar.gz monlor/
	mv -f monlor.tar.gz appstore/
	rm -rf monlor/
	#pack app
	cd apps/
	local name="$1"
	if [ ! -z "$name" ]; then
		if [ "$name" == "all" ]; then
			ls | while read line 
			do
				vapp $line
				tar -zcvf $line.tar.gz $line/
			done 
			$md5 ./*.tar.gz > ../md5.txt
		else
			vapp $name
			tar -zcvf $name.tar.gz $name/
			if [ "`uname -s`" == "Darwin" ]; then
				sed -i "" "/$name/d" ../md5.txt
			else
				sed -i "/$name/d" ../md5.txt
			fi
			$md5 ./$name.tar.gz >> ../md5.txt
		fi
		mv -f ./*.tar.gz ../appstore
	fi
}

localgit() {
	git add .
	git commit -m "`date +%Y-%m-%d`"
}

github() {
	git remote rm origin
	git remote add origin https://github.com/monlor/Monlor-Tools.git
	git push origin master -f
}

coding() {
	git remote rm origin
	git remote add origin https://git.coding.net/monlor/Monlor-Tools.git
	git push origin master -f
}

testing() {
	git remote rm origin
	git remote add origin https://git.coding.net/monlor/Monlor-Test.git
	git push origin master -f
}

reset() {
	
	git checkout --orphan latest_branch
   	git add -A
  	git commit -am "`date +%Y-%m-%d`"
   	git branch -D master
   	git branch -m master
   #	git push -f origin master
	# github
	# coding

}

case $1 in 
	all) 
		localgit
		github
		coding
		testing
		;;
	github)
		localgit
		github		
		;;
	coding)
		localgit
		coding
		;;
	push)
		localgit
		github
		coding
		;;
	pack) 
		[ "$2" == "-v" -o "$3" == "-v" ] && vtools
		[ "$2" == "-v" ] && pack || pack $2
		;;
	test)
		localgit
		testing
		;;
	reset)
		reset
		;;
esac
