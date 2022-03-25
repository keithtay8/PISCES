#!/bin/bash
# CIS Ubuntu 20.04
# 1.8.1 (Raspbian) Ensure X11 Window System (GUI) is removed;;;1.8.1: success
# 1.9 Ensure updates, patches, and additional security software are installed (Manual);;;1.9: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! $(dpkg -s x11-common | grep -E '(Status:|not installed)') ]]; then
		echo "$audit"
	else
		echo -e 'X-11 Window Packages for the Desktop GUI are installed, manually uninstall them using:\napt-get remove --purge x11-common\napt-get autoremove'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	timeout 30 apt upgrade | grep -P '0(\s+)upgraded,(\s+)0(\s+)newly(\s+)installed'
	[[ $? -eq 0 ]] && echo "$audit" || (apt upgrade -y && echo '1.9: success')
fi
echo "$breakpoint"