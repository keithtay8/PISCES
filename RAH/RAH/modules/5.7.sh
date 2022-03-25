#!/bin/bash
# CIS Ubuntu 20.04
# 5.7 Ensure access to the su command is restricted (Automated);;;5.7: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ $(grep -P '^auth.+pam_wheel.so.+group=.+' /etc/pam.d/su) ]]; then
	main_audit=$(grep -P -m 1 '^auth.+pam_wheel.so.+group=.+' /etc/pam.d/su | grep -oP 'group=.+' | cut -d '=' -f 2)
	if [[ $(grep "main_$audit" /etc/group | wc -l) = 1 ]]; then
		echo "$audit"
	else
		echo "There should be no users in the '$main_audit' group"
		echo "$wr_p"
	fi
else
	flag=1
fi

if [[ $flag = 1 ]]; then
	if [[ ! -f 'su.backup' ]]; then
		cp '/etc/pam.d/su' 'su.backup'
		echo '"/etc/pam.d/su" has been backed up to "./su.backup"'
	fi
	groupadd sugroup
	if [[ ! $(grep -P 'auth\s+required\s+pam_wheel.so\s+use_uid\s+group=sugroup' /etc/pam.d/su) ]]; then echo -e 'auth\trequired\tpam_wheel.so\tuse_uid\tgroup=sugroup' >> /etc/pam.d/su ; fi
	echo '5.7: success'
fi