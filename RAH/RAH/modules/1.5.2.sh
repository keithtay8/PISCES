#!/bin/bash
# CIS Ubuntu 20.04
# 1.5.2 Ensure address space layout randomization (ASLR) is enabled (Automated);;;1.5.2: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ $(sysctl kernel.randomize_va_space) != 'kernel.randomize_va_space = 2' ]] && [[ ! $(grep -Es "^\s*kernel\.randomize_va_space\s*=\s*([0-1]|[3-9]|[1-9][0-9]+)"/etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /run/sysctl.d/*.conf) ]]; then
	if [[ -f '/etc/sysctl.conf' ]]; then
		if [[ ! $(grep 'kernel.randomize_va_space' '/etc/sysctl.conf') ]]; then
			if [[ ! -f 'sysctl.conf.backup' ]] && [[ -f '/etc/sysctl.conf' ]]; then
				cp '/etc/sysctl.conf' './sysctl.conf.backup'
				echo "'/etc/sysctl.conf' has been backed up to './sysctl.conf.backup'"
			fi
			echo 'kernel.randomize_va_space = 2' >> '/etc/sysctl.conf'
		else
			echo "There is already an entry for 'kernel.randomize_va_space' in '/etc/sysctl.conf'"
			echo "Please manually set it to 'kernel.randomize_va_space = 2'"
			echo "$wr_p"
			trig=1
		fi
	fi
	
	if [[ ! $trig ]]; then
		for file in /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /run/sysctl.d/*.conf; do
			if [ -f "$file" ]; then
				if [[ ! -f "$(basename $file).backup" ]] && [[ -f "$file" ]]; then
					cp "$file" "./$(basename $file).backup"
					echo "'$file' has been backed up to './$(basename $file).backup'"
				fi
				grep -Esq "^\s*kernel\.randomize_va_space\s*=\s*([0-1]|[3-9]|[1-9][0-9]+)" "$file" && sed -ri 's/^\s*kernel\.randomize_va_space\s*=\s*([0-1]|[3-9]|[1-9][0-9]+)/# &/gi' "$file"
			fi
		done
		
		sysctl -w kernel.randomize_va_space=2
	fi
else
	echo "$audit"
fi && echo '1.5.2: success'