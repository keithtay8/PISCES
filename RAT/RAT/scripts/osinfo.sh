#!/bin/bash

get_osinfo() {
	### Get OS-related info
	echo "=== OS ==="
	echo "- Operating System -"
	echo "Operating System: $(cat /etc/os-release | grep PRETTY_NAME= | egrep -o '".+"')"
	echo "Kernel version: $(cat /proc/version)"
	echo "Hostname: $(hostname)"
}

get_networkinfo() {
	### Get network interfaces
	echo "=== NETWORKING ==="
	echo "- All Network Interfaces -" && echo "$(ip a)"
	
	## Get Routing Table
	echo -e "\n- Network Routing Table -" && echo "$(netstat -rn)" && echo ""
	
	## Get open ports
	echo "- Open ports -" && echo "$(netstat -tulpn 2>/dev/null | grep 'LISTEN')"
}

get_filesystem() {
	### Get file system information, mount points
	echo "=== FILESYSTEM ==="
	echo "- Filesystem Table (/etc/fstab) -" && cat /etc/fstab 2>/dev/null	
	echo -e "\n- Mounts: -" && mount 2>/dev/null	
	if [[ ! $(grep "[[:space:]]ro[[:space:],]" /proc/mounts | grep /boot) ]]; then
		echo '(!) Boot partition is not READ-ONLY'
	else
		echo 'Boot partition is READ-ONLY'
	fi
}


get_cron() {
	## Return all cron jobs, from linuxprivchecker.py
	echo "=== CRON TASKS ==="
	echo "- Scheduled cron jobs -" && ls -al /etc/cron* 2>/dev/null
	echo -e "\n- Writeable cron directories -" && $(ls -aRl /etc/cron* 2>/dev/null | awk '$1 ~ /w.$/' 2>/dev/null)
	echo -e "\n- Users' cron jobs -" && crontab -l 2>/dev/null
}

get_displays() {
	## Get version of xrandr and RandR reports, output is different
	echo "=== DISPLAY OUTPUTS ==="
	
	if [[ ! ${users[@]} ]]; then
		IFS=$'\n' users=($(grep -vP '(nologin|sync|false)' /etc/passwd))
	fi
	for a_user in ${users[@]}; do
		IFS=$oldIFS target=($(echo $a_user | tr ':' ' '))
		#IFS=$'\n' hdmi=($(sudo -H -u ${target[0]} DISPLAY=:0 xrandr 2>/dev/null| grep -P ^HDMI))
		IFS=$'\n' hdmi=($(su -c 'DISPLAY=:0 xrandr 2>/dev/null| grep -P ^HDMI' ${target[0]}))
		echo "- ${target[0]} -"
		if [[ ${hdmi[@]} ]]; then
			printf "%s\n" "${hdmi[@]}"
		else
			echo 'No detected displays'
		fi
	done
	IFS=$oldIFS
}

get_languages() {
	## Find and return programming languages
	echo "=== DEVELOPMENT TOOLS ==="
	echo "- Fetch installed programming languages -"
	which awk perl python ruby gcc cc vi vim nmap find netcat nc wget tftp ftp 2>/dev/null
}

get_envvar() {
	## Find and return ENV
	echo '=== Find ENV variables ==='
	echo '- All current ENV variables -'
	printenv
}
