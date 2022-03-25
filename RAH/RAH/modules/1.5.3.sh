#!/bin/bash
# CIS Ubuntu 20.04
# 1.5.3 Ensure prelink is not installed (Automated);;;1.5.3: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ $(dpkg -s prelink | grep -E '(Status:|not installed)') ]]; then
	$(prelink -ua
	apt purge prelink) && echo '1.5.3: success'
else
	echo "$audit"
fi