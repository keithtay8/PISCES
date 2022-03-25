#!/bin/bash
# CIS Ubuntu 20.04
# 3.1.1 [L2] Disable IPv6 (Manual);;;3.1.1: success
# 3.1.2 [L2] Ensure wireless interfaces are disabled (Automated);;;3.1.2: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'


if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	
	if [[ ! $(sysctl net.ipv6.conf.all.disable_ipv6 | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ $(grep 'net.ipv6.conf.all.disable_ipv6 = 1' /etc/sysctl.conf) ]]; then
			sed -i '/^net.ipv6.conf.all.disable_ipv6\s*=\s*0/c\net.ipv6.conf.all.disable_ipv6 = 1' /etc/sysctl.conf
		else
			echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
		fi
	fi
	if [[ ! $(sysctl net.ipv6.conf.default.disable_ipv6 | grep "=\s*1$") ]]; then
		flag=1
		if [[ $(grep 'net.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf) ]]; then
			sed -i '/^net.ipv6.conf.default.disable_ipv6\s*=\s*0/c\net.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf
		else
			echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
		fi
	fi
	if [[ ! $flag ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv6.conf.all.disable_ipv6=1
		sysctl -w net.ipv6.conf.default.disable_ipv6=1
		sysctl -w net.ipv6.route.flush=1
		echo '3.1.1: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	main_audit=$(
	if command -v nmcli >/dev/null 2>&1 ; then
		if nmcli radio all | grep -Eq '\s*\S+\s+disabled\s+\S+\s+disabled\b'; then
			echo "Wireless is not enabled"
		else
			nmcli radio all
		fi
	elif [ -n "$(find /sys/class/net/*/ -type d -name wireless)" ]; then
		t=0
		mname=$(for driverdir in $(find /sys/class/net/*/ -type d -name wireless | xargs -0 dirname); do basename "$(readlink -f "$driverdir"/device/driver/module)";done | sort -u)
		for dm in $mname; do
			if grep -Eq "^\s*install\s+$dm\s+/bin/(true|false)" /etc/modprobe.d/*.conf; then
				/bin/true
			else
				echo "$dm is not disabled"
				t=1
			fi
		done
		[ "$t" -eq 0 ] && echo "Wireless is not enabled"
	else
		echo "Wireless is not enabled"
	fi)
	if [[ $main_audit = 'Wireless is not enabled' ]]; then
		echo "$audit"
	else
		if command -v nmcli >/dev/null 2>&1 ; then
			nmcli radio all off
		else
			if [ -n "$(find /sys/class/net/*/ -type d -name wireless)" ]; then
				mname=$(for driverdir in $(find /sys/class/net/*/ -type d -name wireless | xargs -0 dirname); do basename "$(readlink -f "$driverdir"/device/driver/module)";done | sort -u)
				for dm in $mname; do
					echo "install $dm /bin/true" >> /etc/modprobe.d/disable_wireless.conf
				done
			fi
		fi
		echo '3.1.2: success'
	fi
fi
echo "$breakpoint"
