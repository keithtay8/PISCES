#!/bin/bash
# CIS Ubuntu 20.04
# 2.2.1 Ensure time synchronization is in use (Automated);;;2.2.1: success
# 2.2.2 Ensure rsh client is not installed (Automated);;;2.2.2: success
# 2.2.3 Ensure talk client is not installed (Automated);;;2.2.3: success
# 2.2.4 Ensure telnet client is not installed (Automated);;;2.2.4: success
# 2.2.5 Ensure LDAP client is not installed (Automated);;;2.2.5: success
# 2.2.6 Ensure RPC is not installed (Automated);;;2.2.6: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

audit_lst=('nis' 'rsh-client' 'talk' 'telnet' 'ldap-utils' 'rpcbind')
for count in $(seq 0 5); do
	if [[ ${BASH_ARGV:$count:1} = 1 ]]; then
		if [[ ! $(dpkg -s ${audit_lst[$count]} | grep -E '(Status:|not installed)' 2>/dev/null) ]]; then
			echo "$audit"
		else
			apt purge "${audit_lst[$count]}" -y 2>/dev/null || apt purge "${audit_lst[$count]}" -y 2>/dev/null
		fi && echo "2.2.$(( count+1 )): success"
	fi
	echo "$breakpoint"
done