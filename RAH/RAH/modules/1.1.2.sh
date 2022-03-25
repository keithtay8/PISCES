#!/bin/bash
# CIS Ubuntu 20.04
# 1.1.2 Ensure /tmp is configured (Automated);;;1.1.2: success
# 1.1.6 Ensure /dev/shm is configured (Automated);;;1.1.6: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'


if (( ${#BASH_ARGV} == 2 )); then
	### 1.1.2
	cmd='tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0'
	if [[ ${BASH_ARGV:0:1} = 1 ]]; then
		if [[ ! $(findmnt -n /tmp | grep -P '(?=.*nodev)(?=.*nosuid)(?=.*noexec)/tmp') ]]; then
			if [[ -f /etc/fstab ]]; then
				if [[ ! $(findmnt -n /tmp) ]]; then
					echo "$cmd" >> '/etc/fstab' && echo '1.1.2: success' || echo '1.1.2: failed'
				elif [[ $(findmnt -n /tmp) ]] && [[ ! $(grep -P '(?=.*nodev)(?=.*nosuid)(?=.*noexec)\s/tmp\s' '/etc/fstab') ]]; then
					echo '/tmp entry already exists, please manually modify this to include "noexec,nodev,nosuid"' && echo "$wr_p"
				fi
			fi
		else
			echo "$audit"
		fi
	fi
	echo "$breakpoint"

	### 1.1.6
	cmd='tmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid,seclabel 0 0'
	cmd2='mount -o remount,noexec,nodev,nosuid /dev/shm'
	if [[ ${BASH_ARGV:1:1} = 1 ]]; then
		if [[ ! $(findmnt -n /dev/shm | grep -P '(?=.*nodev)(?=.*nosuid)(?=.*noexec)/dev/shm') ]]; then
			if [[ -f /etc/fstab ]]; then
				if [[ ! $(findmnt -n /dev/shm) ]]; then
					echo "$cmd" >> '/etc/fstab' && $cmd2 && echo '1.1.6: success' || echo '1.1.6: failed'
				elif [[ $(findmnt -n /dev/shm) ]] && [[ ! $(grep -P '(?=.*nodev)(?=.*nosuid)(?=.*noexec)\s/dev/shm\s' '/etc/fstab') ]]; then
					echo '/dev/shm entry already exists, please manually modify this to include "noexec,nodev,nosuid"' && echo "$wr_p"
				fi
			fi
		else
			echo "$audit"
		fi
	fi
	echo "$breakpoint"
fi