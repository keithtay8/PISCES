#!/bin/bash
# CIS Ubuntu 20.04
# 1.1.22 Ensure sticky bit is set on all world-writable directories (Automated);;;1.1.22: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if (( ${#BASH_ARGV} == 1 )); then
	if [[ $(df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null) ]]; then
		df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs -I '{}' chmod a+t '{}' && echo '1.1.22: success' || echo '1.1.22: failed'
	else
		echo "$audit"
	fi
fi