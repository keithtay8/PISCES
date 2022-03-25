#!/bin/bash
# CIS Ubuntu 20.04
# 5.5.1.1 Ensure minimum days between password changes is configured (Automated);;;5.5.1.1: success
# 5.5.1.2 Ensure password expiration is 365 days or less (Automated);;;5.5.1.2: success
# 5.5.1.3 Ensure password expiration warning days is 7 or more (Automated);;;5.5.1.3: success
# 5.5.1.4 Ensure inactive password lock is 30 days or less (Automated);;;5.5.1.4: success
# 5.5.1.5 Ensure all users last password change date is in the past (Automated);;;5.5.1.5: success
# 5.5.2 Ensure system accounts are secured (Automated);;;5.5.2: success
# 5.5.3 Ensure default group for the root account is GID 0 (Automated);;;5.5.3: success
# 5.5.4 Ensure default user umask is 027 or more restrictive (Automated);;;5.5.4: success
# 5.5.5 Ensure default user shell timeout is 900 seconds or less (Automated);;;5.5.5: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

oldIFS=$IFS
if [[ ! -f 'login.defs.backup' ]]; then
	cp '/etc/login.defs' 'login.defs.backup'
	echo '"/etc/login.defs" has been backed up to "./login.defs.backup"'
fi

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	flag=0 flag2=0
	if (( $(grep PASS_MIN_DAYS /etc/login.defs | grep -P '^PASS_MIN_DAYS\s[0-9]+' | grep -oE [0-9]+) < 1 )); then
		flag=1
	fi
	if [[ $(awk -F : '(/^[^:]+:[^!*]/ && $4 < 1){print $1 " " $4}' /etc/shadow) ]]; then
		flag2=1
	fi
	if [[ $flag = 1 ]] || [[ $flag2 = 1 ]]; then
		if [[ $flag = 1 ]]; then
			if [[ ! -f 'login.defs.backup' ]] && [[ -f '/etc/login.defs' ]]; then
				cp '/etc/login.defs' 'login.defs.backup'
				echo '"/etc/login.defs" has been backed up to "./login.defs.backup"'
			fi
			sed -i '/^PASS_MIN_DAYS\s\+0$/c\PASS_MIN_DAYS 1' '/etc/login.defs'
		fi
		if [[ $flag2 = 1 ]]; then
			IFS=$'\n' main_audit=($(awk -F : '(/^[^:]+:[^!*]/ && $4 < 1){print $1 " " $4}' /etc/shadow))
			for username_date in ${main_audit[@]}; do
				chage --mindays 1 $(echo "$username_date" | cut -d ' ' -f 1)
			done
			IFS=$oldIFS
		fi
		echo '5.5.1.1: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	flag=0 flag2=0
	if (( $(grep PASS_MAX_DAYS /etc/login.defs | grep -P '^PASS_MAX_DAYS\s[0-9]+' | grep -oE '[0-9]+') > 365 )); then
		flag=1
	fi
	if [[ $(awk -F: '(/^[^:]+:[^!*]/ && ($5>365)){print $1 " " $5}' /etc/shadow) ]]; then
		flag2=1
	fi
	if [[ $flag = 1 ]] || [[ $flag2 = 1 ]]; then
		if [[ $flag = 1 ]]; then
			if [[ ! -f 'login.defs.backup' ]] && [[ -f '/etc/login.defs' ]]; then
				cp '/etc/login.defs' 'login.defs.backup'
				echo '"/etc/login.defs" has been backed up to "./login.defs.backup"'
			fi
			sed -i '/^PASS_MAX_DAYS\s\+[0-9]\+$/c\PASS_MAX_DAYS 365' '/etc/login.defs'
		fi
		if [[ $flag2 = 1 ]]; then
			IFS=$'\n' main_audit=($(awk -F: '(/^[^:]+:[^!*]/ && ($5>365)){print $1 " " $5}' /etc/shadow))
			for username_date in ${main_audit[@]}; do
				chage --maxdays 365 $(echo "$username_date" | cut -d ' ' -f 1)
			done
			IFS=$oldIFS
		fi
		echo '5.5.1.2: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	flag=0 flag2=0
	if (( $(grep PASS_WARN_AGE /etc/login.defs | grep -P '^PASS_WARN_AGE\s[0-9]+' | grep -oE '[0-9]+') < 7 )); then
		flag=1
	fi
	if [[ $(awk -F: '(/^[^:]+:[^!*]/ && $6<7){print $1 " " $6}' /etc/shadow) ]]; then
		flag2=1
	fi
	if [[ $flag = 1 ]] || [[ $flag2 = 1 ]]; then
		if [[ $flag = 1 ]]; then
			if [[ ! -f 'login.defs.backup' ]] && [[ -f '/etc/login.defs' ]]; then
				cp '/etc/login.defs' 'login.defs.backup'
				echo '"/etc/login.defs" has been backed up to "./login.defs.backup"'
			fi
			sed -i '/^PASS_WARN_AGE\s\+[0-9]\+$/c\PASS_WARN_AGE 7' '/etc/login.defs'
		fi
		if [[ $flag2 = 1 ]]; then
			IFS=$'\n' main_audit=($(awk -F: '(/^[^:]+:[^!*]/ && $6<7){print $1 " " $6}' /etc/shadow))
			for username_date in ${main_audit[@]}; do
				chage --warndays 7 $(echo "$username_date" | cut -d ' ' -f 1)
			done
			IFS=$oldIFS
		fi
		echo '5.5.1.3: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	flag=0
	if (( $(useradd -D | grep INACTIVE | grep -oP '(-)?[0-9]+') > 30 )); then
		flag=1
	fi
	if [[ $(awk -F: '(/^[^:]+:[^!*]/ && ($7~/(\s*|-1)/ || $7>30)){print $1 " " $7}' /etc/shadow) ]]; then
		flag2=1
	fi
	if [[ $flag = 1 ]] || [[ $flag2 = 1 ]]; then
		if [[ $flag = 1 ]]; then
			useradd -D -f 30
		fi
		if [[ $flag2 = 1 ]]; then
			IFS=$'\n' main_audit=($(awk -F: '(/^[^:]+:[^!*]/ && ($7~/(\s*|-1)/ || $7>30)){print $1 " " $7}' /etc/shadow))
			for username_date in ${main_audit[@]}; do
				chage --inactive 30 $(echo "$username_date" | cut -d ' ' -f 1)
			done
			IFS=$oldIFS
		fi
		echo '5.5.1.4: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:4:1} = 1 ]]; then
	flag=0
	if [[ $(awk -F : '/^[^:]+:[^!*]/{print $1}' /etc/shadow | while read -r usr; do [ "$(date --date="$(chage --list "$usr" | grep '^Last password change' | cut -d: -f2)" +%s)" -gt "$(date "+%s")" ] && echo "user: $usr password change date: $(chage --list "$usr" | grep '^Last password change' | cut -d: -f2)"; done) ]]; then
		flag=1
		echo 'Nothing should be returned'
		echo 'Refer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 448)'
		echo "$wr_p"
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:5:1} = 1 ]]; then
	if [[ $(awk -F: '$1!~/(root|sync|shutdown|halt|^\+)/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $7!~/((\/usr)?\/sbin\/nologin)/ && $7!~/(\/bin)?\/false/ {print}' /etc/passwd) ]] && [[ $(awk -F: '($1!~/(root|^\+)/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"') {print $1}' /etc/passwd | xargs -I '{}' passwd -S '{}' | awk '($2!~/LK?/) {print $1}') ]]; then
		# The following command will set all system accounts to a non login shell
		awk -F: '$1!~/(root|sync|shutdown|halt|^\+)/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $7!~/((\/usr)?\/sbin\/nologin)/ && $7!~/(\/bin)?\/false/ {print $1}' /etc/passwd | while read -r user; do usermod -s "$(which nologin)" "$user"; done
		# The following command will automatically lock not root system accounts:
		awk -F: '($1!~/(root|^\+)/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"') {print $1}' /etc/passwd | xargs -I '{}' passwd -S '{}' | awk '($2!~/LK?/) {print $1}' | while read -r user; do usermod -L "$user"; done
		
		echo 'Manual remediation for 1) setting the shell for any accounts returned by the audit to nologin and 2) locking any non root accounts returned by the audit required'
		echo 'Refer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 449)'
		echo -e 'Remediations applied:\n3)all system accounts to a non login shell\n4)Automatically locked not-root system accounts'
		echo "$wr_p"
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:6:1} = 1 ]]; then
	if [[ $(grep "^root:" /etc/passwd | cut -f4 -d:) = 0 ]]; then
		echo "$audit"
	else
		usermod -g 0 root && echo '5.5.3: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:7:1} = 1 ]]; then
	main_audit=$(
	passing=""
	grep -Eiq '^\s*UMASK\s+(0[0-7][2-7]7|[0-7][2-7]7)\b' /etc/login.defs && grep -Eqi '^\s*USERGROUPS_ENAB\s*"?no"?\b' /etc/login.defs && grep -Eq '^\s*session\s+(optional|requisite|required)\s+pam_umask\.so\b' /etc/pam.d/common-session && passing=true
	grep -REiq '^\s*UMASK\s+\s*(0[0-7][2-7]7|[0-7][2-7]7|u=(r?|w?|x?)(r?|w?|x?)(r?|w?|x?),g=(r?x?|x?r?),o=)\b' /etc/profile* /etc/bash.bashrc* && passing=true
	[ "$passing" = true ] && echo "Default user umask is set"
	)
	audit_2=$(
	grep -RPi '(^|^[^#]*)\s*umask\s+([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b|[0-7][01][0-7]\b|[0-7][0-7][0-6]\b|(u=[rwx]{0,3},)?(g=[rwx]{0,3},)?o=[rwx]+\b|(u=[rwx]{1,3},)?g=[^rx]{1,3}(,o=[rwx]{0,3})?\b)' /etc/login.defs /etc/profile* /etc/bash.bashrc*
	)
	if [[ $main_audit = "Default user umask is set" ]] && [[ ! $audit_2 ]]; then
		echo "$audit"
	else
		if [[ ! -f 'login.defs.backup' ]] && [[ -f '/etc/login.defs' ]]; then
			cp '/etc/login.defs' 'login.defs.backup'
			echo '"/etc/login.defs" has been backed up to "./login.defs.backup"'
		fi
		grep -RPi '(^|^[^#]*)\s*umask\s+([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b|[0-7][01][0-7]\b|[0-7][0-7][0-6]\b|(u=[rwx]{0,3},)?(g=[rwx]{0,3},)?o=[rwx]+\b|(u=[rwx]{1,3},)?g=[^rx]{1,3}(,o=[rwx]{0,3})?\b)' /etc/login.defs /etc/profile* /etc/bash.bashrc*
		sed -i '/UMASK\s\+[0-7]\{3\}/c\UMASK 027' /etc/login.defs
		sed -i '/USERGROUPS_ENAB\sno/c\USERGROUPS_ENAB yes' /etc/login.defs
		
		if [[ ! -f 'common-session.backup' ]] && [[ -f '/etc/pam.d/common-session' ]]; then
			cp '/etc/pam.d/common-session' 'common-session.backup'
			echo '"/etc/pam.d/common-session" has been backed up to "./common-session.backup"'
		fi
		if [[ ! $(cat /etc/pam.d/common-session | grep -P 'session\s+optional\s+pam_umask.so') ]]; then echo -e 'session\toptional\tpam_umask.so' >> /etc/pam.d/common-session; fi
		echo '5.5.4: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:8:1} = 1 ]]; then
	main_audit=$(
	output1="" output2=""
	[ -f /etc/bash.bashrc ] && BRC="/etc/bash.bashrc"
	for f in "$BRC" /etc/profile /etc/profile.d/*.sh ; do
		grep -Pq '^\s*([^#]+\s+)?TMOUT=(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9])\b' "$f" && grep -Pq '^\s*([^#]+;\s*)?readonly\s+TMOUT(\s+|\s*;|\s*$|=(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9]))\b' "$f" && grep -Pq '^\s*([^#]+;\s*)?export\s+TMOUT(\s+|\s*;|\s*$|=(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9]))\b' "$f" && output1="$f"
	done
	grep -Pq '^\s*([^#]+\s+)?TMOUT=(9[0-9][1-9]|9[1-9][0-9]|0+|[1-9]\d{3,})\b' /etc/profile /etc/profile.d/*.sh "$BRC" && output2=$(grep -Ps '^\s*([^#]+\s+)?TMOUT=(9[0-9][1-9]|9[1-9][0-9]|0+|[1-9]\d{3,})\b' /etc/profile /etc/profile.d/*.sh $BRC)
	if [ -n "$output1" ] && [ -z "$output2" ]; then
		echo -e "PASSED: TMOUT is configured in: \"$output1\""
	else
		[ -z "$output1" ] && echo -e "FAILED: TMOUT is not configured"
		[ -n "$output2" ] && echo -e "FAILED: TMOUT is incorrectly configured in: \"$output2\""
	fi
	)
	if [[ $(echo $main_audit | grep 'FAILED') ]]; then
		if [[ ! -f 'profile.backup' ]] && [[ -f '/etc/profile' ]]; then
			cp '/etc/profile' 'profile.backup'
			echo '"/etc/profile" has been backed up to "./profile.backup"'
		fi
		if [[ $(cat '/etc/profile' | grep -P -m 1 'TMOUT=[0-9]*') ]]; then
			if (( $(cat '/etc/profile' | grep -P -m 1 'TMOUT=[0-9]*' | grep -oP [0-9]+) <= 0 )) || (( $(cat '/etc/profile' | grep -P -m 1 'TMOUT=[0-9]*' | grep -oP [0-9]+) > 900 )); then
				if [[ ! -f 'profile.backup' ]] && [[ -f '/etc/profile' ]]; then
					cp '/etc/profile' 'profile.backup'
					echo '"/etc/profile" has been backed up to "./profile.backup"'
				fi
				sed -i 's/TMOUT=[0-9]\+/TMOUT=900/' /etc/profile
			else
				echo "$audit"
			fi
		else
			echo 'readonly TMOUT=900 ; export TMOUT' >> '/etc/profile'
		fi
		echo '5.5.5: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"