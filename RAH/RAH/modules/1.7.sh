#!/bin/bash
# CIS Ubuntu 20.04
# 1.7.1 Ensure message of the day is configured properly (Automated);;;1.7.1: success
# 1.7.2 Ensure local login warning banner is configured properly (Automated);;;1.7.2: success
# 1.7.3 Ensure remote login warning banner is configured properly (Automated);;;1.7.3: success
# 1.7.4 Ensure permissions on /etc/motd are configured (Automated);;;1.7.4: success
# 1.7.5 Ensure permissions on /etc/issue are configured (Automated);;;1.7.5: success
# 1.7.6 Ensure permissions on /etc/issue.net are configured (Automated);;;1.7.6: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

init_lst=('/etc/motd' '/etc/issue' '/etc/issue.net')
cmds_lst=('' 'Authorized uses only. All activity may be monitored and reported.' 'Authorized uses only. All activity may be monitored and reported.')
for count in $(seq 0 2); do
	if [[ ${BASH_ARGV:$count:1} = '1' ]]; then
		if [[ ! $(grep -Eis "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2| sed -e 's/"//g'))" ${init_lst[$count]}) ]]; then
			echo "$audit"
		else
			if [[ ! -f "$(basename ${init_lst[$count]}).backup" ]]; then
				cp "${init_lst[$count]}" "./$(basename ${init_lst[$count]}).backup"
				echo "'${init_lst[$count]}' has been backed up to './$(basename ${init_lst[$count]}).backup'"
			fi
			echo "${cmds_lst[$count]}" > "${init_lst[$count]}" && echo "1.7.$(( $count+1 )): success"
		fi
	fi
	echo "$breakpoint"
done


for count in $(seq 3 5); do
	if [[ ${BASH_ARGV:$count:1} = '1' ]]; then
		count=$(( $count-3 ))
		if [[ ! -f ${init_lst[$count]} ]] || [[ $(stat -L ${init_lst[$count]} | grep -P '(?=.*644)(?=.*Uid:\s+\(\s+0/\s+root\))(?=.*Gid:\s+\(\s+0/\s+root\))Access:') ]]; then
			echo "$audit"
		else
			chown root:root $(readlink -e ${init_lst[$count]})
			chmod u-x,go-wx $(readlink -e ${init_lst[$count]}) && echo "1.7.$count: success"
		fi
	fi
	echo "$breakpoint"
done