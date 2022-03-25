#!/bin/bash
# CIS Ubuntu 20.04
# 5.1.1 Ensure cron daemon is enabled and running (Automated);;;5.1.1: success
# 5.1.2 Ensure permissions on /etc/crontab are configured (Automated);;;5.1.2: success
# 5.1.3 Ensure permissions on /etc/cron.hourly are configured (Automated);;;5.1.3: success
# 5.1.4 Ensure permissions on /etc/cron.daily are configured (Automated);;;5.1.4: success
# 5.1.5 Ensure permissions on /etc/cron.weekly are configured (Automated);;;5.1.5: success
# 5.1.6 Ensure permissions on /etc/cron.monthly are configured (Automated);;;5.1.6: success
# 5.1.7 Ensure permissions on /etc/cron.d are configured (Automated);;;5.1.7: success
# 5.1.8 Ensure cron is restricted to authorized users (Automated);;;5.1.8: success
# 5.1.9 Ensure at is restricted to authorized users (Automated);;;5.1.9: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! $(systemctl is-enabled cron) = 'enabled' ]] || [[ ! $(systemctl status cron | grep 'Active: active (running) ') ]]; then
		systemctl --now enable cron && echo '5.1.1: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

cron_lst=('' '/etc/crontab' '/etc/cron.hourly/' '/etc/cron.daily/' '/etc/cron.weekly/' '/etc/cron.monthly/' '/etc/cron.d/')
for count in $(seq 1 6); do
	if [[ ${BASH_ARGV:$count:1} = 1 ]]; then
		if [[ ! $(stat "${cron_lst[$count]}" | grep -P '\([0-9][0-7]00/.+root.+root\)') ]]; then
			$(chown root:root "${cron_lst[$count]}"
			chmod og-rwx "${cron_lst[$count]}") && echo "5.1.$(( $count + 1 )): success"
		else
			echo "$audit"
		fi
	fi
	echo "$breakpoint"
done

if [[ ${BASH_ARGV:7:1} = 1 ]]; then
	if [[ ! $(stat /etc/cron.deny) ]] && [[ $(stat /etc/cron.allow | grep -P '\([0-9][0-7][40][0]/.+root.+root\)') ]]; then
		echo "$audit"
	else
		rm /etc/cron.deny
		touch /etc/cron.allow
		chmod g-wx,o-rwx /etc/cron.allow
		chown root:root /etc/cron.allow
		echo '5.1.8: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:8:1} = 1 ]]; then
	if [[ ! $(stat /etc/at.deny) ]] && [[ $(stat /etc/at.allow | grep -P '\([0-9][0-7][40][0]/.+root.+root\)') ]]; then
		echo "$audit"
	else
		rm /etc/at.deny
		touch /etc/at.allow
		chmod g-wx,o-rwx /etc/at.allow
		chown root:root /etc/at.allow
		echo '5.1.9: success'
	fi
fi
echo "$breakpoint"