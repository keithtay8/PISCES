#!/bin/bash
# CIS Ubuntu 20.04
# 4.4 Ensure logrotate assigns appropriate permissions (Automated);;;4.4: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

oldIFS=$IFS IFS=$'\n' main_audit=($(grep -Es "^\s*create\s+\S+" /etc/logrotate.conf /etc/logrotate.d/* | grep -E -v "\s(0)?[0-6][04]0\s"))
if [[ ${main_audit[@]} ]]; then
	if [[ ! -f 'logrotate.conf.backup' ]]; then
		cp '/etc/logrotate.conf' 'logrotate.conf.backup'
		echo '"/etc/logrotate.conf" has been backed up to "./logrotate.conf.backup"'
	fi
	
	for line in ${audit[@]}; do
		IFS=$oldIFS
		filename=$(echo $line | cut -d ':' -f1) policy=($(echo $line | cut -d ':' -f2 | xargs))
		if [[ $(grep "$policy" "$filename") ]]; then
			sed -i "s/$(echo ${policy[@]} | xargs)/$(echo ${policy[0]} 640 ${policy[2]} ${policy[3]} | xargs)/" "$filename"
		fi
	done
	#if [[ ! $(grep '#create' '/etc/logrotate.conf') ]]; then sed -i 's/create/#create/' '/etc/logrotate.conf'; fi
	#if [[ ! $(grep '# Hardening Script' '/etc/logrotate.conf') ]]; then echo -e '\n# Hardening Script' >> '/etc/logrotate.conf'; fi
	#if [[ ! $(grep -P '^create' '/etc/logrotate.conf') ]]; then echo 'create 0640 root utmp' >> '/etc/logrotate.conf'; fi
	echo '4.4: success'
else
	echo "$audit"
fi