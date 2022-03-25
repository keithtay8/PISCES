#!/bin/bash
# CIS Ubuntu 20.04
# 2.3 Ensure nonessential services are removed or masked (Manual);;;2.3: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ! $(lsof -i -P -n | grep -v "(ESTABLISHED)") ]]; then
	echo "$audit"
else
	echo 'Review the above services, determine which is unneccessary. For those, do "apt purge <package_name>"'
	echo 'OR If required packages have a dependency, stop and mask the service by doing the following: "systemctl --now mask <service_name>"'
	echo "$wr_p"
fi