#!/bin/bash
# CIS Ubuntu 20.04
# 1.6.1.1 Ensure AppArmor is installed (Automated);;;1.6.1.1: success
# 1.6.1.2 Ensure AppArmor is enabled in the bootloader configuration (Automated);;;1.6.1.2: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = '1' ]]; then
	if [[ $(dpkg -s apparmor | grep -E '(Status:|not installed)') != 'Status: install ok installed' ]]; then
		apt install apparmor -y && echo '1.6.1.1: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = '1' ]]; then
	if [[ ! $(cat /boot/cmdline.txt | grep -v "apparmor=1") ]] && [[ ! $(cat /boot/cmdline.txt | grep -v "security=apparmor") ]]; then
		echo "$audit"
	else
		cp /boot/cmdline.txt cmdline_backup.txt; echo 'Backed up /boot/cmdline.txt to ./cmdline_backup.txt'
		if [[ $(cat /boot/cmdline.txt | grep -v "apparmor=1") ]]; then
			echo "$(cat /boot/cmdline.txt) apparmor=1" > '/boot/cmdline.txt'
		fi
		if [[ $(cat /boot/cmdline.txt | grep -v "security=apparmor") ]]; then
			echo "$(cat /boot/cmdline.txt) security=apparmor" > '/boot/cmdline.txt'
		fi
	fi && echo '1.6.1.2: success'
fi
echo "$breakpoint"