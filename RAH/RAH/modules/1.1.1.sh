#!/bin/bash
# CIS Ubuntu 20.04
# 1.1.1.1 Ensure mounting of cramfs filesystems is disabled (Automated);;;cramfs: success
# 1.1.1.2 Ensure mounting of freevxfs filesystems is disabled (Automated);;;freevxfs: success
# 1.1.1.3 Ensure mounting of jffs2 filesystems is disabled (Automated);;;jffs2: success
# 1.1.1.4 Ensure mounting of hfs filesystems is disabled (Automated);;;hfs: success
# 1.1.1.5 Ensure mounting of hfsplus filesystems is disabled (Automated);;;hfsplus: success
# 1.1.1.6 Ensure mounting of squashfs filesystems is disabled (Manual) [L2];;;squashfs: success
# 1.1.1.7 Ensure mounting of udf filesystems is disabled (Automated);;;udf: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

init_lst=('cramfs' 'freevxfs' 'jffs2' 'hfs' 'hfsplus' 'squashfs' 'udf')


target_directory='/etc/modprobe.d'
if [[ -d $target_directory ]]; then
	for count in $(seq 0 6); do
		if [[ ${BASH_ARGV:$count:1} = 1 ]]; then
			fs_type=${init_lst[$count]}
			if  [[ ! $(modprobe -n -v "$fs_type" | grep -v "($fs_type|install)") ]] || [[ $(lsmod | grep $fs_type) ]]; then
				if [[ ! -f "$target_directory/$fs_type.conf" ]]; then
					echo "install $fs_type /bin/true" >> "$target_directory/$fs_type.conf"
					$(rmmod "$fs_type")
				else
					echo "$wr_p"
				fi && echo "$fs_type: success"
			else
				echo "$audit"
			fi || echo "$audit"
		fi
		echo "$breakpoint"
	done
fi