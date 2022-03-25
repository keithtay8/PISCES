#!/bin/bash
# CIS Ubuntu 20.04
# 6.1.2 Ensure permissions on /etc/passwd are configured (Automated);;;6.1.2: success
# 6.1.3 Ensure permissions on /etc/passwd- are configured (Automated);;;6.1.3: success
# 6.1.4 Ensure permissions on /etc/group are configured (Automated);;;6.1.4: success
# 6.1.5 Ensure permissions on /etc/group- are configured (Automated);;;6.1.5: success
# 6.1.6 Ensure permissions on /etc/shadow are configured (Automated);;;6.1.6: success
# 6.1.7 Ensure permissions on /etc/shadow- are configured (Automated);;;6.1.7: success
# 6.1.8 Ensure permissions on /etc/gshadow are configured (Automated);;;6.1.8: success
# 6.1.9 Ensure permissions on /etc/gshadow- are configured (Automated);;;6.1.9: success
# 6.1.10 Ensure no world writable files exist (Automated);;;6.1.10: success
# 6.1.11 Ensure no unowned files or directories exist (Automated);;;6.1.11: success
# 6.1.12 Ensure no ungrouped files or directories exist (Automated);;;6.1.12: success
# 6.1.13 Audit SUID executables (Manual);;;6.1.13: success
# 6.1.14 Audit SGID executables (Manual);;;6.1.14: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

lst_audit=('/etc/passwd' '/etc/passwd-' '/etc/group' '/etc/group-' '/etc/shadow' '/etc/shadow-' '/etc/gshadow' '/etc/gshadow-')
for count in $(seq 0 7); do
	if [[ ${BASH_ARGV:$count:1} = 1 ]]; then
		if (( $count < 4 )); then
			if [[ $(stat "${lst_audit[$count]}") =~ \([0-9]644.+root.+root\) ]]; then
				echo "$audit"
			else
				$(chown root:root "${lst_audit[$count]}"
				chmod u-x,go-wx "${lst_audit[$count]}") && echo "6.1.$(( $count+2 )): success"
			fi
		else
			if [[ $(stat "${lst_audit[$count]}") =~ \([0-9]640.+root.+(root|shadow)\) ]]; then
				echo "$audit"
			else
				$(chown root:root "${lst_audit[$count]}"
				chmod u-x,g-wx,o-rwx "${lst_audit[$count]}") && echo "6.1.$(( $count+2 )): success"
			fi
		fi
		
	fi
	echo "$breakpoint"
done


lst_audit=(
	'xargs -I '{}' find '{}' -xdev -type f -perm -0002'
	'xargs -I '{}' find '{}' -xdev -nouser'
	'xargs -I '{}' find '{}' -xdev -nogroup'
	'xargs -I '{}' find '{}' -xdev -type f -perm -4000'
	'xargs -I '{}' find '{}' -xdev -type f -perm -2000'
)
for count in $(seq 8 12); do
	if [[ ${BASH_ARGV:8:1} = 1 ]]; then
		if [[ ! $(df --local -P | awk '{if (NR!=1) print $6}' | ${lst_audit[$(( $count-8 ))]}) ]]; then
			echo "$audit"
		else
			echo -e "Refer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page $(( 480+2*$(( $count-7 )) )))"
			echo "$wr_p"
		fi
	fi
	echo "$breakpoint"
done
