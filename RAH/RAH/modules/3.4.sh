#!/bin/bash
# CIS Ubuntu 20.04
# 3.4.1 [L2] Ensure DCCP is disabled (Automated);;;3.4.1: success
# 3.4.2 [L2] Ensure SCTP is disabled (Automated);;;3.4.2: success
# 3.4.3 [L2] Ensure RDS is disabled (Automated);;;3.4.3: success
# 3.4.4 [L2] Ensure TIPC is disabled (Automated);;;3.4.4: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'


init_lst=('dccp' 'sctp' 'rds' 'tipc')

for count in $(seq 0 3); do
	if [[ ${BASH_ARGV:$count:1} = 1 ]]; then
		if [[ $(modprobe -n -v ${init_lst[$count]}) ]] && [[ $(modprobe -n -v ${init_lst[$count]} | grep -v 'install /bin/true') ]] || [[ $(lsmod | grep dccp) ]]; then
			echo "install ${init_lst[$count]} /bin/true" >> /etc/modprobe.d/${init_lst[$count]}.conf && echo "3.4.$(( $count+1 )): success"
		else
			echo "$audit"
		fi || echo "$audit"
	fi
	echo "$breakpoint"
done