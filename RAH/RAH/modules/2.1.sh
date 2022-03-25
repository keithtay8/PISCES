#!/bin/bash
# CIS Ubuntu 20.04
# 2.1.1.1 Ensure time synchronization is in use (Automated);;;2.1.1.1: success
# 2.1.1.2 Ensure systemd-timesyncd is configured (Automated);;;2.1.1.2: success
# 2.1.2 Ensure X Window System is not installed (Automated;;;2.1.2: success
# 2.1.3 Ensure Avahi Server is not installed (Automated);;;2.1.3: success
# 2.1.4 [L2] Ensure CUPS is not installed (Automated);;;2.1.4: success
# 2.1.5 Ensure DHCP Server is not installed (Automated);;;2.1.5: success
# 2.1.6 Ensure LDAP server is not installed (Automated);;;2.1.6: success
# 2.1.7 Ensure NFS is not installed (Automated);;;2.1.7: success
# 2.1.8 Ensure DNS Server is not installed (Automated);;;2.1.8: success
# 2.1.9 Ensure FTP Server is not installed (Automated);;;2.1.9: success
# 2.1.10 Ensure HTTP server is not installed (Automated);;;2.1.10: success
# 2.1.11 Ensure IMAP and POP3 server are not installed (Automated);;;2.1.11: success
# 2.1.12 Ensure Samba is not installed (Automated);;;2.1.12: success
# 2.1.13 Ensure HTTP Proxy Server is not installed (Automated);;;2.1.13: success
# 2.1.14 Ensure SNMP Server is not installed (Automated);;;2.1.14: success
# 2.1.15 Ensure mail transfer agent is configured for local-only mode (Automated);;;2.1.15: success
# 2.1.16 Ensure rsync service is not installed (Automated);;;2.1.16: success
# 2.1.17 Ensure NIS Server is not installed (Automated);;;2.1.17: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'


if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ $(systemctl is-enabled systemd-timesyncd) = 'enabled' ]] || [[ ! $(dpkg -s chrony 2>/dev/null) ]] | [[ $(dpkg -s ntp 2>/dev/null) ]]; then
		echo "$audit"
	else
		echo 'No Time-Synchronization method has been configured'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ ! $(dpkg -s ntp 2>/dev/null) ]] && [[ ! $(dpkg -s chrony 2>/dev/null) ]] && [[ $(systemctl is-enabled systemd-timesyncd.service) = 'enabled' ]] && [[ $(timedatectl status | grep -P 'NTP\sservice:\sactive') ]]; then
		echo "$audit"
	else
		if [[ ! ts_flag ]]; then
			ts_flag='systemd-timesyncd'
			
			if [[ ! -f 'timesyncd.conf.backup' ]]; then
				cp '/etc/systemd/timesyncd.conf' './timesyncd.conf.backup'
				echo "'/etc/systemd/timesyncd.conf' has been backed up to './timesyncd.conf.backup'"
			fi
			
			if [[ ! $(grep -P '^NTP=.+' '/etc/systemd/timesyncd.conf') ]]; then
				flag=1; echo 'NTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org #Servers listed should be In Accordence With Local Policy' >> '/etc/systemd/timesyncd.conf'
			else
				echo 'NTP server entries exist, please manually confirm that the right values are in /etc/systemd/timesyncd.conf'
			fi
			if [[ ! $(grep -P '^FallbackNTP=.+' '/etc/systemd/timesyncd.conf') ]]; then
				flag=1; echo 'FallbackNTP=2.debian.pool.ntp.org 3.debian.pool.ntp.org #Servers listed should be In Accordence With Local Policy' >> '/etc/systemd/timesyncd.conf'
			else
				echo 'Fallback NTP server entries exist, please manually confirm that the right values are in /etc/systemd/timesyncd.conf'
			fi
			if [[ ! $(grep -P '^RootDistanceMax=.+' '/etc/systemd/timesyncd.conf') ]]; then
				flag=1; echo 'RootDistanceMax=1 #should be In Accordence With Local Policy' >> '/etc/systemd/timesyncd.conf'
			else
				echo 'RootDistanceMax entry exists, please manually confirm that the right values are in /etc/systemd/timesyncd.conf'
			fi
			
			if [[ $flag ]]; then
				$(echo '/etc/systemd/timesyncd.conf has been backed up to ./timesyncd_backup.conf'
				apt purge ntp -y &>/dev/null
				apt purge chrony -y &>/dev/null
				systemctl start systemd-timesyncd.service
				timedatectl set-ntp true) && echo '2.1.1.2: success'
			else
				rm 'timesyncd_backup.conf'
				echo "$wr_p"
			fi
		fi
	fi || echo '2.1.1.2: systemd-timesyncd configuration failed'
fi
echo "$breakpoint"


audit_lst=('0' '1' 'xserver-xorg*' 'avahi-daemon' 'cups' 'isc-dhcp-server' 'slapd' 'nfs-kernel-server' 'bind9' 'vsftpd' 'apache2' 'dovecot-imapd dovecot-pop3d' 'samba' 'squid' 'snmpd' '15' 'rsync' 'nis')
for count in $(seq 2 17); do
	if [[ ${BASH_ARGV:$count:1} = 1 ]]; then
		if [[ "$count" = 2 ]]; then
			if [[ ! $(dpkg -l {$audit_lst[$count]} 2>/dev/null) ]]; then
				echo "$audit"
			else
				echo 'Desktop GUI installed, please manually run "apt purge xserver-xorg*" to remove it'
				echo "$wr_p" || echo '2.1.2: success'
			fi
		elif [[ "$count" = 15 ]]; then
			if [[ ! -f 'update-exim4.conf.conf.backup' ]]; then
				cp ' /etc/exim4/update-exim4.conf.conf' './update-exim4.conf.conf.backup'
				echo '"/etc/exim4/update-exim4.conf.conf" has been backed up to "./update-exim4.conf.conf.backup"'
			fi
			
			if [[ ! $(ss -lntu | grep -E ':25\s' | grep -E -v '\s(127.0.0.1|::1):25\s') ]]; then
				echo "$audit"
			else
				declare -A mail_transfer_patch=(
					['dc_eximconfig_configtype']='local'
					['dc_local_interfaces']='127.0.0.1 ; ::1'
					['dc_readhost']=''
					['dc_relay_domains']=''
					['dc_minimaldns']='false'
					['dc_relay_nets']=''
					['dc_smarthost']=''
					['dc_use_split_config']='false'
					['dc_hide_mailname']=''
					['dc_mailname_in_oh']='true'
					['dc_localdelivery']='mail_spool'
				)
				for item in ${!mail_transfer_patch[@]}; do
					if [[ ! -f 'update-exim4.conf.conf.backup' ]]; then
						cp '/etc/exim4/update-exim4.conf.conf' './update-exim4.conf.conf.backup'
						echo "'/etc/exim4/update-exim4.conf.conf' has been backed up to './update-exim4.conf.conf.backup'"
					fi
					if [[ ! $(grep -P "^$item" /etc/ssh/sshd_config) ]]; then
						echo "$item='${mail_transfer_patch[$item]}'" >> /etc/exim4/update-exim4.conf.conf
					else
						sed -i '/^'"$item"'=.\+/c\'"$item='${mail_transfer_patch[$item]}'" '/etc/exim4/update-exim4.conf.conf'
					fi
				done
				systemctl restart exim4
				echo '2.1.15: success'
			fi
		else
			if [[ ! $(dpkg -s ${audit_lst[$count]} | grep -E '(Status:|not installed)' 2>/dev/null) ]]; then
				echo "$audit"
			else
				if [[ "$count" = 3 ]]; then
					systemctl stop avahi-daaemon.service; systemctl stop avahi-daemon.socket 2>/dev/null
				fi
				apt purge "${audit_lst[$count]}" -y 2>/dev/null || apt purge "${audit_lst[$count]}" -y 2>/dev/null
			fi && echo "2.1.$count: success"
		fi
	fi
	echo "$breakpoint"
done





