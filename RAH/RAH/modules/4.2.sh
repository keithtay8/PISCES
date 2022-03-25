#!/bin/bash
# CIS Ubuntu 20.04
# 4.2.1.1 Ensure rsyslog is installed (Automated);;;4.2.1.1: success
# 4.2.1.2 Ensure rsyslog Service is enabled (Automated);;;4.2.1.2: success
# 4.2.1.3 Ensure logging is configured (Manual);;;4.2.1.3: success
# 4.2.1.4 Ensure rsyslog default file permissions configured (Automated);;;4.2.1.4: success
# 4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host (Automated);;;4.2.1.5: success
# 4.2.1.6 Ensure remote rsyslog messages are only accepted on designated log hosts. (Manual);;;4.2.1.6: success
# 4.2.2.1 Ensure journald is configured to send logs to rsyslog (Automated);;;4.2.2.1: success
# 4.2.2.2 Ensure journald is configured to compress large log files (Automated);;;4.2.2.2: success
# 4.2.2.3 Ensure journald is configured to write logfiles to persistent disk (Automated);;;4.2.2.3: success
# 4.2.3 Ensure permissions on all logfiles are configured (Automated);;;4.2.3: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! $(dpkg -s rsyslog | grep 'install ok installed') ]]; then
		apt install rsyslog -y
		if [[ $(dpkg --list | grep rsyslog) ]]; then
			echo '4.2.1.1: success'
		fi
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:0:1} = 1 ]] && [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ ! $(systemctl is-enabled rsyslog | grep 'enabled') ]]; then
		systemctl --now enable rsyslog && echo '4.2.1.2: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"
	
if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	declare -A rule_lines=(
	['*.emerg']=':omusrmsg:*'
	['auth,authpriv.*']='/var/log/auth.log'
	['mail.*']='-/var/log/mail'
	['mail.info']='-/var/log/mail.info'
	['mail.warning']='-/var/log/mail.warn'
	['mail.err']='/var/log/mail.err'
	['news.crit']='-/var/log/news/news.crit'
	['news.err']='-/var/log/news/news.err'
	['news.notice']='-/var/log/news/news.notice'
	['*.=warning;*.=err']='-/var/log/warn'
	['*.crit']='/var/log/warn'
	['*.*;mail.none;news.none']='-/var/log/messages'
	['local0,local1.*']='-/var/log/localmessages'
	['local2,local3.*']='-/var/log/localmessages'
	['local4,local5.*']='-/var/log/localmessages'
	['local6,local7.*']='-/var/log/localmessages'
	)
	if [[ ! -f 'rsyslog.conf.backup' ]]; then
		cp '/etc/rsyslog.conf' 'rsyslog.conf.backup'
		echo '"/etc/rsyslog.conf" has been backed up to "./rsyslog.conf.backup"'
	fi
	flag=0
	for line in ${!rule_lines[@]}; do
		# Escape sensitive characters
		literal_line_for_regex=$(
		for count in $(seq 0 $(( ${#line}-1 ))); do
			if [[ $(echo "${line:$count:1}" | grep -P '[\.\*\+\?\^\$\[\]]') ]]; then
				echo -n '\'"${line:$count:1}"
			else
				echo -n "${line:$count:1}"
			fi
		done)
		literal_value_for_regex=$(
		value=${rule_lines[$line]}
		for count in $(seq 0 $(( ${#value}-1 ))); do
			if [[ $(echo "${value:$count:1}" | grep -P '[\.\*\+\?\^\$\[\]]') ]]; then
				echo -n '\'"${value:$count:1}"
			else
				echo -n "${value:$count:1}"
			fi
		done)
		if [[ ! $(grep -P '^'"$literal_line_for_regex"'\s+'"$literal_value_for_regex"'$' '/etc/rsyslog.conf') ]]; then
			flag=1
			if [[ $(grep -P '^'"$literal_line_for_regex"'\s+' '/etc/rsyslog.conf') ]]; then
				sed -i "/$literal_line_for_regex\s\+.\+/c\\$line		${rule_lines[$line]}" '/etc/rsyslog.conf'
			else
				if [[ ! $(grep '# Hardening Script' '/etc/rsyslog.conf') ]]; then
					echo -e '\n# Hardening Script' >> '/etc/rsyslog.conf'
				fi
				echo -e "$line"'\t\t'"${rule_lines[$line]}" >> '/etc/rsyslog.conf'
			fi
		fi
	done
	systemctl reload rsyslog
	if [[ $flag = 0 ]]; then
		echo "$audit"
	else
		flag=0
		echo '4.2.1.3: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	flag=0
	if [[ ! $(grep ^\s*\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf) ]]; then
		flag=1
		if [[ ! -f 'rsyslog.conf.backup' ]]; then
			cp '/etc/rsyslog.conf' 'rsyslog.conf.backup'
			echo '"/etc/rsyslog.conf" has been backed up to "./rsyslog.conf.backup"'
		fi
		echo '$FileCreateMode 0640' >> '/etc/rsyslog.conf'
	else
		oldIFS=$IFS IFS=$'\n'
		for line in $(grep ^\s*\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf); do
			if [[ ! ${line: -4} =~ -r[w-]-[r-]----- ]]; then
				if [[ ! -f "$(echo $line | cut -d ':' -f 1)" ]]; then
					cp "$(echo $line | cut -d ':' -f 1)" "$(echo $line | cut -d ':' -f 1).backup"
					echo "\"$(echo $line | cut -d ':' -f 1)\" has been backed up to \"./$(echo $line | cut -d ':' -f 1).backup\""
				fi
				flag=1
				sed -i '/^\$FileCreateMode\s\+.\+/c\$FileCreateMode 0640' "$(echo $line | cut -d ':' -f 1)"
			fi
		done
		IFS=$oldIFS
	fi
	[[ $flag = 1 ]] && echo '4.2.1.4: success' || echo "$audit"
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:4:1} = 1 ]]; then
	if [[ ! $(grep -E '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf) ]] && [[ ! $(grep -E '^[^#]\s*\S+\.\*\s+@' /etc/rsyslog.conf /etc/rsyslog.d/*.conf) ]]; then
		echo -e 'Please refer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Pg 338) for the remediation steps\n<<WR_P>>'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:5:1} = 1 ]]; then
	a=$(grep '$ModLoad imtcp' /etc/rsyslog.conf /etc/rsyslog.d/*.conf) b=$(grep '$InputTCPServerRun' /etc/rsyslog.conf /etc/rsyslog.d/*.conf)
	if [[ ${a:0:1} = '#' ]] && [[ ${b:0:1} = '#' ]]; then
		echo "$audit"
	else
		if [[ ! $a ]] || [[ ! $b ]]; then
			echo "$audit"
		elif [[ ${a:0:1} != '#' ]] && [[ ${b:0:1} != '#' ]]; then
			echo "$audit"
		else
			echo -e 'All above outputs must either not exist, ALL are commented, or ALL are uncommented.\nPlease refer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Pg 340) for the remediation steps\n<<WR_P>>'
		fi
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:6:1} = 1 ]]; then
	if [[ $(grep -E '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf) ]] || [[  $(grep -E '^[^#]\s*\S+\.\*\s+@' /etc/rsyslog.conf /etc/rsyslog.d/*.conf) ]]; then
		if [[ ! $(grep -e ForwardToSyslog /etc/systemd/journald.conf) = 'ForwardToSyslog=yes' ]]; then
			if [[ ! -f 'journald.conf.backup' ]]; then
				cp '/etc/systemd/journald.conf' 'journald.conf.backup'
				echo '"/etc/systemd/journald.conf" has been backed up to "./journald.conf.backup"'
			fi
			if [[ ! $(grep '# Hardening Script' '/etc/systemd/journald.conf') ]]; then
				echo -e '\n# Hardening Script' >> '/etc/systemd/journald.conf'
			fi
			echo 'ForwardToSyslog=yes' >> '/etc/systemd/journald.conf'
			echo '4.2.2.1: success'
		else
			echo "$audit"
		fi
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:7:1} = 1 ]]; then
	if [[ ! $(grep -P 'Compress(\s)*=(\s)*yes' /etc/systemd/journald.conf) ]]; then
		if [[ ! -f 'journald.conf.backup' ]]; then
			cp '/etc/systemd/journald.conf' 'journald.conf.backup'
			echo '"/etc/systemd/journald.conf" has been backed up to "./journald.conf.backup"'
		fi
		if [[ $(grep -P '#?Compress(\s)*=(\s)*.+' /etc/systemd/journald.conf) ]]; then
			sed -i '/^#\?Compress\s*=\s*.\+/c\Compress=yes' /etc/systemd/journald.conf
		else
			if [[ ! $(grep '# Hardening Script' '/etc/systemd/journald.conf') ]]; then
				echo -e '\n# Hardening Script' >> '/etc/systemd/journald.conf'
			fi
			echo 'Compress=yes' >> '/etc/systemd/journald.conf'
		fi
		echo '4.2.2.2: success'
	else
		echo '<<AUDIT>>'
	fi
fi
echo '<<BREAKPOINT>>'

if [[ ${BASH_ARGV:8:1} = 1 ]]; then
	if [[ ! $(grep -P 'Storage(\s)*=(\s)*persistent' /etc/systemd/journald.conf) ]]; then
		if [[ ! -f 'journald.conf.backup' ]]; then
			cp '/etc/systemd/journald.conf' 'journald.conf.backup'
			echo '"/etc/systemd/journald.conf" has been backed up to "./journald.conf.backup"'
		fi
		if [[ $(grep -P '#?Storage(\s)*=(\s)*.+' /etc/systemd/journald.conf) ]]; then
			sed -i '/^#\?Storage\s*=\s*.\+/c\Storage=persistent' /etc/systemd/journald.conf
		else
			if [[ ! $(grep '# Hardening Script' '/etc/systemd/journald.conf') ]]; then
				echo -e '\n# Hardening Script' >> '/etc/systemd/journald.conf'
			fi
			echo 'Storage=persistent' >> '/etc/systemd/journald.conf'
		fi
		echo '4.2.2.3: success'
	else
		echo '<<AUDIT>>'
	fi
fi
echo '<<BREAKPOINT>>'

if [[ ${BASH_ARGV:9:1} = 1 ]]; then
	find /var/log -type f -ls | grep -vP '\s.{4}[r-]-----\s'
	if [[ $? -eq 1 ]]; then
		echo "$audit"
	else
		find /var/log -type f -exec chmod g-wx,o-rwx "{}" + -o -type d -exec chmod g-w,o-rwx "{}" +
		echo '4.2.3: success'
	fi
fi
echo '<<BREAKPOINT>>'

