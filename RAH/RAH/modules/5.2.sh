#!/bin/bash
# CIS Ubuntu 20.04
# 5.2.1 Ensure sudo is installed (Automated);;;5.2.1: success
# 5.2.2 Ensure sudo commands use pty (Automated);;;5.2.2: success
# 5.2.3 Ensure sudo log file exists (Automated);;;5.2.3: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ $(dpkg -s sudo) ]] || [[ $(dpkg -s sudo-ldap) ]]; then
		echo "$audit"
	else
		apt install sudo -y && echo '5.2.1: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ ! $(grep -Ei '^\s*Defaults\s+([^#]+,\s*)?use_pty(,\s+\S+\s*)*(\s+#.*)?$' /etc/sudoers /etc/sudoers.d/*) ]]; then
		if [[ ! -f 'sudoers.backup' ]]; then
			cp '/etc/sudoers' 'sudoers.backup'
			echo '"/etc/sudoers" has been backed up to "./sudoers.backup"'
		fi
		echo 'Defaults use_pty' | sudo EDITOR='tee -a' visudo && echo '5.2.2: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	if [[ $(grep -Ei '^\s*Defaults\s+logfile=\S+' /etc/sudoers /etc/sudoers.d/*) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sudoers.backup' ]]; then
			cp '/etc/sudoers' 'sudoers.backup'
			echo '"/etc/sudoers" has been backed up to "./sudoers.backup"'
		fi
		echo 'Defaults logfile="/var/log/sudo.log"' | sudo EDITOR='tee -a' visudo && echo '5.2.3: success'
	fi
fi
echo "$breakpoint"