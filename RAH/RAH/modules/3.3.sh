#!/bin/bash
# CIS Ubuntu 20.04
# 3.3.1 Ensure source routed packets are not accepted (Automated);;;3.3.1: success
# 3.3.2 Ensure ICMP redirects are not accepted (Automated);;;3.3.2: success
# 3.3.3 Ensure secure ICMP redirects are not accepted (Automated);;;3.3.3: success
# 3.3.4 Ensure suspicious packets are logged (Automated);;;3.3.4: success
# 3.3.5 Ensure broadcast ICMP requests are ignored (Automated);;;3.3.5: success
# 3.3.6 Ensure bogus ICMP responses are ignored (Automated);;;3.3.6: success
# 3.3.7 Ensure Reverse Path Filtering is enabled (Automated);;;3.3.7: success
# 3.3.8 Ensure TCP SYN Cookies is enabled (Automated);;;3.3.8: success
# 3.3.9 Ensure IPv6 router advertisements are not accepted (Automated);;;3.3.9: (IPv6-enabled) success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'


if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.conf.all.accept_source_route | grep -P "=\s*0$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.all\.accept_source_route' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.all.accept_source_route = 0' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.all\.accept_source_route\s\+.\+/c\net.ipv4.conf.all.accept_source_route = 0' '/etc/sysctl.conf'
		fi
	fi
	if [[ ! $(sysctl net.ipv4.conf.default.accept_source_route | grep -P "=\s*0$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.default\.accept_source_route' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.default.accept_source_route = 0' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.default\.accept_source_route\s\+.\+/c\net.ipv4.conf.all.accept_source_route = 0' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.conf.all.accept_source_route=0
		sysctl -w net.ipv4.conf.default.accept_source_route=0
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.1: success'
	fi
		
	## IPv6 Check
	if [[ $(sysctl net.ipv6.conf.all.disable_ipv6 | grep -P "=\s*1$") ]] && [[ $(sysctl net.ipv6.conf.default.disable_ipv6 | grep "=\s*1$") ]]; then
		if [[ ! -f 'sysctl.conf.backup' ]]; then
			cp '/etc/sysctl.conf' 'sysctl.conf.backup'
			echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
		fi
		flag6=0
		if [[ ! $(sysctl net.ipv6.conf.all.accept_source_route | grep -P "=\s*0$") ]]; then
			flag6=1
			if [[ ! $(grep -P '^net\.ipv6\.conf\.all\.accept_source_route' /etc/sysctl.conf) ]]; then
				echo 'net.ipv6.conf.all.accept_source_route = 0' >> /etc/sysctl.conf
			else
				sed -i '/^net\.ipv6\.conf\.all\.accept_source_route\s\+.\+/c\net.ipv6.conf.all.accept_source_route = 0' '/etc/sysctl.conf'
			fi
		fi
		if [[ ! $(sysctl net.ipv6.conf.default.accept_source_route | grep -P "=\s*0$") ]]; then
			flag6=1
			if [[ ! $(grep -P '^net\.ipv6\.conf\.default\.accept_source_route' /etc/sysctl.conf) ]]; then
				echo 'net.ipv6.conf.default.accept_source_route = 0' >> /etc/sysctl.conf
			else
				sed -i '/^net\.ipv6\.conf\.default\.accept_source_route\s\+.\+/c\net.ipv6.conf.default.accept_source_route = 0' '/etc/sysctl.conf'
			fi
		fi
		if [[ $flag6 = 1 ]]; then
			sysctl -w net.ipv6.conf.all.accept_source_route=0
			sysctl -w net.ipv6.conf.default.accept_source_route=0
			sysctl -w net.ipv6.route.flush=1
			echo '3.3.1: (IPv6-enabled) success'
		fi
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.conf.all.accept_redirects | grep -P "=\s*0$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.all\.accept_redirects' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.all.accept_redirects = 0' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.all\.accept_redirects\s\+.\+/c\net.ipv4.conf.all.accept_redirects = 0' '/etc/sysctl.conf'
		fi
	fi
	if [[ ! $(sysctl net.ipv4.conf.default.accept_redirects | grep -P "=\s*0$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.default\.accept_redirects' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.default.accept_redirects = 0' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.default\.accept_redirects\s\+.\+/c\net.ipv4.conf.default.accept_redirects = 0' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo '<<AUDIT>>'
	else
		sysctl -w net.ipv4.conf.all.accept_redirects=0
		sysctl -w net.ipv4.conf.default.accept_redirects=0
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.2: success'
	fi
		
	## IPv6 Check
	if [[ $(sysctl net.ipv6.conf.all.disable_ipv6 | grep -P "=\s*1$") ]] && [[ $(sysctl net.ipv6.conf.default.disable_ipv6 | grep "=\s*1$") ]]; then
		if [[ ! -f 'sysctl.conf.backup' ]]; then
			cp '/etc/sysctl.conf' 'sysctl.conf.backup'
			echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
		fi
		flag6=0
		if [[ ! $(sysctl net.ipv6.conf.all.accept_redirects | grep -P "=\s*0$") ]]; then
			flag6=1
			if [[ ! $(grep -P '^net\.ipv6\.conf\.all\.accept_redirects' /etc/sysctl.conf) ]]; then
				echo 'net.ipv6.conf.all.accept_redirects = 0' >> /etc/sysctl.conf
			else
				sed -i '/^net\.ipv6\.conf\.all\.accept_redirects\s\+.\+/c\net.ipv6.conf.all.accept_redirects = 0' '/etc/sysctl.conf'
			fi
		fi
		if [[ ! $(sysctl net.ipv6.conf.default.accept_source_route | grep -P "=\s*0$") ]]; then
			flag6=1
			if [[ ! $(grep -P '^net\.ipv6\.conf\.default\.accept_source_route' /etc/sysctl.conf) ]]; then
				echo 'net.ipv6.conf.default.accept_redirects = 0' >> /etc/sysctl.conf
			else
				sed -i '/^net\.ipv6\.conf\.default\.accept_source_route\s\+.\+/c\net.ipv6.conf.default.accept_source_route = 0' '/etc/sysctl.conf'
			fi
		fi
		if [[ $flag6 = 1 ]]; then
			sysctl -w net.ipv6.conf.all.accept_redirects=0
			sysctl -w net.ipv6.conf.default.accept_redirects=0
			sysctl -w net.ipv6.route.flush=1
			echo '3.3.2: (IPv6-enabled) success'
		fi
	fi
fi
echo '<<BREAKPOINT>>'

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.conf.all.secure_redirects | grep -P "=\s*0$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.all\.secure_redirects' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.all.secure_redirects = 0' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.all\.secure_redirects\s\+.\+/c\net.ipv4.conf.all.secure_redirects = 0' '/etc/sysctl.conf'
		fi
	fi
	if [[ ! $(sysctl net.ipv4.conf.default.secure_redirects | grep -P "=\s*0$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.default\.secure_redirects' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.default.secure_redirects = 0' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.default\.secure_redirects\s\+.\+/c\net.ipv4.conf.default.secure_redirects = 0' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.conf.all.secure_redirects=0
		sysctl -w net.ipv4.conf.default.secure_redirects=0
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.3: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.conf.all.log_martians | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.all\.log_martians' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.all.log_martians = 1' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.all\.log_martians\s\+.\+/c\net.ipv4.conf.all.log_martians = 1' '/etc/sysctl.conf'
		fi
	fi
	if [[ ! $(sysctl net.ipv4.conf.default.log_martians | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.default\.log_martians' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.default.log_martians = 1' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.default\.log_martians\s\+.\+/c\net.ipv4.conf.default.log_martians = 1' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.conf.all.log_martians=1
		sysctl -w net.ipv4.conf.default.log_martians=1
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.4: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:4:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.icmp_echo_ignore_broadcasts | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.icmp_echo_ignore_broadcasts' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.icmp_echo_ignore_broadcasts = 1' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.icmp_echo_ignore_broadcasts\s\+.\+/c\net.ipv4.icmp_echo_ignore_broadcasts = 1' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.5: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:5:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.icmp_ignore_bogus_error_responses | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.icmp_ignore_bogus_error_responses' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.icmp_ignore_bogus_error_responses = 1' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.icmp_ignore_bogus_error_responses\s\+.\+/c\net.ipv4.icmp_ignore_bogus_error_responses = 1' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.6: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:6:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.conf.all.rp_filter | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.all\.rp_filter' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.all.rp_filter = 1' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.all\.rp_filter\s\+.\+/c\net.ipv4.conf.all.rp_filter = 1' '/etc/sysctl.conf'
		fi
	fi
	if [[ ! $(sysctl net.ipv4.conf.default.rp_filter | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.conf\.default\.rp_filter' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.conf.default.rp_filter = 1' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.conf\.default\.rp_filter\s\+.\+/c\net.ipv4.conf.default.rp_filter = 1' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.conf.all.rp_filter=1
		sysctl -w net.ipv4.conf.default.rp_filter=1
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.7: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:7:1} = 1 ]]; then
	if [[ ! -f 'sysctl.conf.backup' ]]; then
		cp '/etc/sysctl.conf' 'sysctl.conf.backup'
		echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
	fi
	flag=0
	if [[ ! $(sysctl net.ipv4.tcp_syncookies | grep -P "=\s*1$") ]]; then
		flag=1
		if [[ ! $(grep -P '^net\.ipv4\.tcp_syncookies' /etc/sysctl.conf) ]]; then
			echo 'net.ipv4.tcp_syncookies = 1' >> /etc/sysctl.conf
		else
			sed -i '/^net\.ipv4\.tcp_syncookies\s\+.\+/c\net.ipv4.tcp_syncookies = 1' '/etc/sysctl.conf'
		fi
	fi
	if [[ $flag != 1 ]]; then
		echo "$audit"
	else
		sysctl -w net.ipv4.tcp_syncookies=1
		sysctl -w net.ipv4.route.flush=1
		echo '3.3.8: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:8:1} = 1 ]]; then
	## IPv6 Check
	if [[ $(sysctl net.ipv6.conf.all.disable_ipv6 | grep -P "=\s*1$") ]] && [[ $(sysctl net.ipv6.conf.default.disable_ipv6 | grep "=\s*1$") ]]; then
		if [[ ! -f 'sysctl.conf.backup' ]]; then
			cp '/etc/sysctl.conf' 'sysctl.conf.backup'
			echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
		fi
		flag6=0
		if [[ ! $(sysctl net.ipv6.conf.all.accept_ra | grep -P "=\s*0$") ]]; then
			flag6=1
			if [[ ! $(grep -P '^net\.ipv6\.conf\.all\.accept_ra' /etc/sysctl.conf) ]]; then
				echo 'net.ipv6.conf.all.accept_ra = 0' >> /etc/sysctl.conf
			else
				sed -i '/^net\.ipv6\.conf\.all\.accept_ra\s\+.\+/c\net.ipv6.conf.all.accept_ra = 0' '/etc/sysctl.conf'
			fi
		fi
		if [[ ! $(sysctl net.ipv6.conf.default.accept_ra | grep -P "=\s*0$") ]]; then
			flag6=1
			if [[ ! $(grep -P '^net\.ipv6\.conf\.default\.accept_ra' /etc/sysctl.conf) ]]; then
				echo 'net.ipv6.conf.default.accept_ra = 0' >> /etc/sysctl.conf
			else
				sed -i '/^net\.ipv6\.conf\.default\.accept_ra\s\+.\+/c\net.ipv6.conf.default.accept_ra = 0' '/etc/sysctl.conf'
			fi
		fi
		if [[ $flag6 != 1 ]]; then
			echo "$audit"
		else
			sysctl -w net.ipv6.conf.all.accept_ra=0
			sysctl -w net.ipv6.conf.default.accept_ra=0
			sysctl -w net.ipv6.route.flush=1
			echo '3.3.9: (IPv6-enabled) success'
		fi
	fi
fi
echo "$breakpoint"