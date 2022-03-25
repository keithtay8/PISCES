#!/bin/bash
# CIS Ubuntu 20.04
# 1.3.1 Ensure AIDE is installed (Automated);;;1.3.1: ran

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ! $(dpkg -s aide | grep -E '(Status:|not installed)') = 'Status: install ok installed' ]] || [[ ! $(dpkg -s aide-common | grep -E '(Status:|not installed)') = 'Status: install ok installed' ]]; then
	apt install aide aide-common -y
	if (( $(dpkg --list | grep aide | wc -l) >= 2 )); then
		aideinit -y -f
	fi
elif [[ ! $(timeout 30 aideinit | grep Overwrite) ]]; then
	aideinit -y -f
#else
#	echo "$audit"
fi