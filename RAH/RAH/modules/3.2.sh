#!/bin/bash
# CIS Ubuntu 20.04
# 3.2.1 Ensure packet redirect sending is disabled (Automated);;;3.2.1: success
# 3.2.2 Ensure IP forwarding is disabled (Automated);;;3.2.2: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'


if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]] && [[ -f "/etc/sysctl.conf" ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	
	if [[ ! $(sysctl net.ipv4.conf.all.send_redirects | grep -P "=\s*0$") ]]; then
		flag=1
		echo 'net.ipv4.conf.all.send_redirects = 0' >> /etc/sysctl.conf
	fi
	if [[ ! $(sysctl net.ipv4.conf.all.send_redirects | grep -P "=\s*0$") ]]; then
		flag=1
		echo 'net.ipv4.conf.default.send_redirects = 0' >> /etc/sysctl.conf
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.conf.all.send_redirects=0
		sysctl -w net.ipv4.conf.default.send_redirects=0
		sysctl -w net.ipv4.route.flush=1
		echo '3.2.1: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ ! $(sysctl net.ipv4.ip_forward | grep -P "=\s*0$") ]]; then
		flag=1
	fi
	if [[ $(grep -E -s "^\s*net\.ipv4\.ip_forward\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf) ]]; then
		flag=1
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		# grep -Els "^\s*net\.ipv4\.ip_forward\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri "s/^\s*(net\.ipv4\.ip_forward\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename; done; sysctl -w net.ipv4.ip_forward=0; sysctl -w net.ipv4.route.flush=1
		grep -Els "^\s*net\.ipv4\.ip_forward\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do if [[ ! -f "$(basename $filename).backup" ]] && [[ -f "$filename" ]]; then cp "$filename" "./$(basename $filename).backup"; echo "'$filename' has been backed up to './$(basename $filename).backup'"; fi; sed -ri "s/^\s*(net\.ipv4\.ip_forward\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename; done; sysctl -w net.ipv4.ip_forward=0; sysctl -w net.ipv4.route.flush=1
		echo '3.2.2: success'
	fi
	
	## IPv6 Check
	if [[ $(sysctl net.ipv6.conf.all.disable_ipv6 | grep -P "=\s*1$") ]] && [[ $(sysctl net.ipv6.conf.default.disable_ipv6 | grep "=\s*1$") ]]; then
		# grep -Els "^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri "s/^\s*(net\.ipv6\.conf\.all\.forwarding\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename; done; sysctl -w net.ipv6.conf.all.forwarding=0; sysctl -w net.ipv6.route.flush=1
		grep -Els "^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do if [[ ! -f "$(basename $filename).backup" ]] && [[ -f "$filename" ]]; then cp "$filename" "./$(basename $filename).backup"; echo "'$filename' has been backed up to './$(basename $filename).backup'"; fi; sed -ri "s/^\s*(net\.ipv6\.conf\.all\.forwarding\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename; done; sysctl -w net.ipv6.conf.all.forwarding=0; sysctl -w net.ipv6.route.flush=1
		echo '3.2.2: (IPv6-enabled) success'
	fi
fi
echo "$breakpoint"