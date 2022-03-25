#!/bin/bash
# CIS Ubuntu 20.04
# 3.5.1.1 Ensure ufw is installed (Automated);;;3.5.1.1: success
# 3.5.1.2 Ensure iptables-persistent is not installed with ufw (Automated);;;3.5.1.2: success
# 3.5.1.3 Ensure ufw service is enabled (Automated);;;3.5.1.3: success
# 3.5.1.4 Ensure ufw loopback traffic is configured (Automated);;;3.5.1.4: success
# 3.5.1.5 Ensure ufw outbound connections are configured (Manual);;;3.5.1.5: success
# 3.5.1.6 Ensure ufw firewall rules exist for all open ports (Manual);;;3.5.1.6: success
# 3.5.1.7 Ensure ufw default deny firewall policy (Automated);;;3.5.1.7: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'


if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! $(dpkg -s ufw | grep 'Status: install') ]]; then
		apt install ufw -y && echo '3.5.1.1: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ ! $(dpkg-query -s iptables-persistent) ]]; then
		echo "$audit"
	else
		apt purge iptables-persistent -y && echo '3.5.1.2: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	if [[ $(systemctl is-enabled ufw | grep 'enabled') ]] && [[ $(ufw status | grep 'Status: active') ]]; then
		echo "$audit"
	else
		ufw allow proto tcp from any to any port 22
		echo 'y' | ufw enable && echo '3.5.1.3: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	ufw status verbose | grep -Pzq '(?s)(Anywhere\son\slo\s+ALLOW\sIN\s+Anywhere).+(Anywhere\s+DENY\sIN\s+127\.0\.0\.0/8).+(Anywhere\s\(v6\)\son\slo\s+ALLOW\sIN\s+Anywhere\s\(v6\)).+(Anywhere\s\(v6\)\s+DENY\sIN\s+::1)'
	if [[ $? -eq 0 ]]; then
		echo "$audit"
	else
		ufw allow in on lo
		ufw allow out on lo
		ufw deny in from 127.0.0.0/8
		ufw deny in from ::1
		echo '3.5.1.4: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:4:1} = 1 ]]; then
	ufw status numbered
	ufw status numbered | grep -P 'Anywhere\s+ALLOW\sOUT\s+Anywhere\son\sall\s+\(out\)'
	[[ $? -eq 0 ]] && echo "$audit" || (ufw allow out on all; echo '3.5.1.5: success')
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:5:1} = 1 ]]; then
	ss -4tuln
	ufw status verbose
	echo 'No changes will be made, please manually confirm if all outbound rules are correct'
	echo 'For each port identified in the audit which does not have a firewall rule establish a proper rule for accepting inbound connections: "ufw allow in <port>/<tcp or udp protocol>"'
	echo "$wr_p"
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:6:1} = 1 ]]; then
	#ufw status verbose | grep -Pq 'Default:\sdeny\s\(incoming\),\sallow\s\(outgoing\),\s(disabled|deny)\s\(routed\)'
	ufw status verbose | grep -Pq 'Default:\s(deny|reject)\s\(incoming\),\sallow\s\(outgoing\),\s(deny|reject|disabled)\s\(routed\)'
	if [[ $? -eq 0 ]]; then
		echo "$audit"
	else
		ufw status verbose
		ufw allow git
		ufw allow in http
		ufw allow in https
		ufw allow out 53
		ufw logging on
		ufw allow ssh
		
		ufw default deny incoming
		#ufw default deny outgoing
		#echo 'UFW DEFAULT DENY POLICY ENABLED. All connections will be rejected unless a specific rule has been made for each of them'
		ufw default allow outgoing
		ufw default deny routed
		echo '3.5.1.7: success'
	fi
fi
echo "$breakpoint"