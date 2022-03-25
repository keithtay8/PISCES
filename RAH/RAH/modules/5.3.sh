#!/bin/bash
# CIS Ubuntu 20.04
# 5.3.1 Ensure permissions on /etc/ssh/sshd_config are configured (Automated);;;5.3.1: success
# 5.3.2 Ensure permissions on SSH private host key files are configured (Automated);;;5.3.2: success
# 5.3.3 Ensure permissions on SSH public host key files are configured (Automated);;;5.3.3: success
# 5.3.4 Ensure SSH access is limited (Automated);;;5.3.4: success
# 5.3.5 Ensure SSH LogLevel is appropriate (Automated);;;5.3.5: success
# 5.3.6 Ensure SSH X11 forwarding is disabled (Automated);;;5.3.6: success
# 5.3.7 Ensure SSH MaxAuthTries is set to 4 or less (Automated);;;5.3.7: success
# 5.3.8 Ensure SSH IgnoreRhosts is enabled (Automated);;;5.3.8: success
# 5.3.9 Ensure SSH HostbasedAuthentication is disabled (Automated);;;5.3.9: success
# 5.3.10 Ensure SSH root login is disabled (Automated);;;5.3.10: success
# 5.3.11 Ensure SSH PermitEmptyPasswords is disabled (Automated);;;5.3.11: success
# 5.3.12 Ensure SSH PermitUserEnvironment is disabled (Automated);;;5.3.12: success
# 5.3.13 Ensure only strong Ciphers are used (Automated);;;5.3.13: success
# 5.3.14 Ensure only strong MAC algorithms are used (Automated);;;5.3.14: success
# 5.3.15 Ensure only strong Key Exchange algorithms are used;;;5.3.15: success
# 5.3.16 Ensure SSH Idle Timeout Interval is configured (Automated);;;5.3.16: success
# 5.3.17 Ensure SSH LoginGraceTime is set to one minute or less (Automated);;;5.3.17: success
# 5.3.18 Ensure SSH warning banner is configured (Automated);;;5.3.18: success
# 5.3.19 Ensure SSH PAM is enabled (Automated);;;5.3.19: success
# 5.3.20 Ensure SSH AllowTcpForwarding is disabled (Automated);;;5.3.20: success
# 5.3.21 Ensure SSH MaxStartups is configured (Automated);;;5.3.21: success
# 5.3.22 Ensure SSH MaxSessions is limited (Automated);;;5.3.22: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! $(stat '/etc/ssh/sshd_config') =~ \([0-9][0-7]00.+root.+root\) ]]; then
		$(chown root:root '/etc/ssh/sshd_config'
		chmod og-rwx '/etc/ssh/sshd_config') && echo '5.3.1: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ $(find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec stat {} \; | grep -P 'Access: \([0-9]{4}' | grep -v -P '\([0-9][246]00.+root.+root\)') ]]; then
		find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chown root:root {} \;
		find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chmod u-x,go-rwx {} \;
		echo '5.3.2: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	if [[ $(find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec stat {} \; | grep -P 'Access: \([0-9]{4}' | grep -v -P '\([0-9][246]44.+root.+root\)') ]]; then
		find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chown root:root {} \;
		find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chmod u-x,go-rwx {} \;
		echo '5.3.3: success'
	else
		echo "$audit"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Ei '^\s*(allow|deny)(users|groups)\s+\S+') ]]; then
		echo "$audit"
	else
		echo 'There are several options available to limit which users and group can access the system via SSH. It is recommended that at least one of the following options be leveraged:'
		echo -e '"AllowUsers:", "AllowGroups: "DenyUsers:", "DenyGroups: "\nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 386)'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:4:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep loglevel) =~ (INFO|VERBOSE) ]] && [[ ! $(grep -is 'loglevel' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf | grep -Evi '(VERBOSE|INFO)') ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^LogLevel' /etc/ssh/sshd_config) ]]; then
			echo 'LogLevel INFO' >> /etc/ssh/sshd_config
		else
			sed -i '/^LogLevel\s\+.\+/c\LogLevel INFO' '/etc/ssh/sshd_config'
		fi
		echo '5.3.5: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:5:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i x11forwarding) =~ no ]] && [[ ! $(grep -Eis '^\s*x11forwarding\s+yes' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^X11Forwarding' /etc/ssh/sshd_config) ]]; then
			echo 'X11Forwarding no' >> /etc/ssh/sshd_config
		else
			sed -i '/^X11Forwarding\s\+yes/c\X11Forwarding no' '/etc/ssh/sshd_config'
		fi
		echo '5.3.6: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:6:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep maxauthtries) =~ 4 ]] && [[ ! $(grep -Eis '^\s*maxauthtries\s+([5-9]|[1-9][0-9]+)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^MaxAuthTries' /etc/ssh/sshd_config) ]]; then
			echo 'MaxAuthTries 4' >> /etc/ssh/sshd_config
		else
			sed -i '/^MaxAuthTries\s\+[0-9]\+/c\MaxAuthTries 4' '/etc/ssh/sshd_config'
		fi
		echo '5.3.7: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:7:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep ignorerhosts) =~ yes ]] && [[ ! $(grep -Eis '^\s*ignorerhosts\s+no\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^IgnoreRhosts' /etc/ssh/sshd_config) ]]; then
			echo 'IgnoreRhosts yes' >> /etc/ssh/sshd_config
		else
			sed -i '/^IgnoreRhosts\s\+yes/c\IgnoreRhosts yes' '/etc/ssh/sshd_config'
		fi
		echo '5.3.8: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:8:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep hostbasedauthentication) =~ no ]] && [[ ! $(grep -Eis '^\s*HostbasedAuthentication\s+yes' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^HostbasedAuthentication' /etc/ssh/sshd_config) ]]; then
			echo 'HostbasedAuthentication no' >> /etc/ssh/sshd_config
		else
			sed -i '/^HostbasedAuthentication\s\+yes/c\HostbasedAuthentication\sno' '/etc/ssh/sshd_config'
		fi
		echo '5.3.9: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:9:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permitrootlogin) =~ no ]] && [[ ! $(grep -Eis '^\s*PermitRootLogin\s+yes' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^PermitRootLogin' /etc/ssh/sshd_config) ]]; then
			echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
		else
			sed -i '/^PermitRootLogin\s\+.\+/c\PermitRootLogin no' '/etc/ssh/sshd_config'
		fi
		echo '5.3.10: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:10:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permitemptypasswords) =~ no ]] && [[ ! $(grep -Eis '^\s*PermitEmptyPasswords\s+yes' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^PermitEmptyPasswords' /etc/ssh/sshd_config) ]]; then
			echo 'PermitEmptyPasswords no' >> /etc/ssh/sshd_config
		else
			sed -i '/^PermitEmptyPasswords\s\+.\+/c\PermitEmptyPasswords no' '/etc/ssh/sshd_config'
		fi
		echo '5.3.11: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:11:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permituserenvironment) =~ no ]] && [[ ! $(grep -Eis '^\s*PermitUserEnvironment\s+yes' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^PermitUserEnvironment' /etc/ssh/sshd_config) ]]; then
			echo 'PermitUserEnvironment no' >> /etc/ssh/sshd_config
		else
			sed -i '/^PermitUserEnvironment\s\+.\+/c\PermitUserEnvironment no' '/etc/ssh/sshd_config'
		fi
		echo '5.3.12: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:12:1} = 1 ]]; then
	if [[ ! $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Ei '^\s*ciphers\s+([^#]+,)?(3descbc|aes128-cbc|aes192-cbc|aes256-cbc|arcfour|arcfour128|arcfour256|blowfishcbc|cast128-cbc|rijndael-cbc@lysator.liu.se)\b') ]] && [[ ! $(grep -Eis '^\s*ciphers\s+([^#]+,)?(3des-cbc|aes128-cbc|aes192-cbc|aes256-cbc|arcfour|arcfour128|arcfour256|blowfish-cbc|cast128-cbc|rijndaelcbc@lysator.liu.se)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^PermitUserEnvironment' /etc/ssh/sshd_config) ]]; then
			echo 'Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr' >> /etc/ssh/sshd_config
		else
			sed -i '/^Ciphers\s\+.\+/c\Ciphers chacha20-poly1305@openssh\.com,aes256-gcm@openssh\.com,aes128-gcm@openssh\.com,aes256-ctr,aes192-ctr,aes128-ctr' '/etc/ssh/sshd_config'
		fi
		echo '5.3.13: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:13:1} = 1 ]]; then
	if [[ ! $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Ei '^\s*macs\s+([^#]+,)?(hmacmd5|hmac-md5-96|hmac-ripemd160|hmac-sha1|hmac-sha1-96|umac64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmacripemd160-etm@openssh\.com|hmac-sha1-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b') ]] && [[ ! $(grep -Eis '^\s*macs\s+([^#]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmacsha1|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac128-etm@openssh\.com)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^MACs' /etc/ssh/sshd_config) ]]; then
			echo 'MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256' >> /etc/ssh/sshd_config
		else
			sed -i '/^MACs\s\+.\+/c\MACs hmac-sha2-512-etm@openssh\.com,hmac-sha2-256-etm@openssh\.com,hmac-sha2-512,hmac-sha2-256' '/etc/ssh/sshd_config'
		fi
		echo '5.3.14: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:14:1} = 1 ]]; then
	if [[ ! $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Ei '^\s*kexalgorithms\s+([^#]+,)?(diffie-hellman-group1-sha1|diffie-hellmangroup14-sha1|diffie-hellman-group-exchange-sha1)\b') ]] && [[ ! $(grep -Ei '^\s*kexalgorithms\s+([^#]+,)?(diffie-hellman-group1-sha1|diffiehellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b' /etc/ssh/sshd_config) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^KexAlgorithms' /etc/ssh/sshd_config) ]]; then
			echo 'KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellmangroup14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffiehellman-group-exchange-sha256' >> /etc/ssh/sshd_config
		else
			sed -i '/^KexAlgorithms\s\+.\+/c\KexAlgorithms curve25519-sha256,curve25519-sha256@libssh\.org,diffie-hellmangroup14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffiehellman-group-exchange-sha256' '/etc/ssh/sshd_config'
		fi
		echo '5.3.15: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:15:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep clientaliveinterval) =~ [1-300] ]] && [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep clientalivecountmax) =~ [1-3] ]] && [[ ! $(grep -Eis '^\s*clientaliveinterval\s+(0|3[0-9][1-9]|[4-9][0-9][0-9]|[1-9][0-9][0-9][0-9]+|[6-9]m|[1-9][0-9]+m)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]] && [[ ! $(grep -Eis '^\s*ClientAliveCountMax\s+(0|[4-9]|[1-9][0-9]+)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^ClientAliveInterval' /etc/ssh/sshd_config) ]]; then
			echo 'ClientAliveInterval 300' >> /etc/ssh/sshd_config
		else
			sed -i '/^ClientAliveInterval\s\+.\+/c\ClientAliveInterval 300' '/etc/ssh/sshd_config'
		fi
		if [[ ! $(grep -P '^ClientAliveCountMax' /etc/ssh/sshd_config) ]]; then
			echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config
		else
			sed -i '/^ClientAliveCountMax\s\+.\+/c\ClientAliveCountMax 3' '/etc/ssh/sshd_config'
		fi
		echo '5.3.16: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:16:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep logingracetime) =~ [1-60]|(1m) ]] && [[ ! $(grep -Eis '^\s*LoginGraceTime\s+(0|6[1-9]|[7-9][0-9]|[1-9][0-9][0-9]+|[^1]m)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^LoginGraceTime' /etc/ssh/sshd_config) ]]; then
			echo 'LoginGraceTime 60' >> /etc/ssh/sshd_config
		else
			sed -i '/^LoginGraceTime\s\+.\+/c\LoginGraceTime 60' '/etc/ssh/sshd_config'
		fi
		echo '5.3.17: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:17:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep banner) =~ /etc/issue\.net ]] && [[ ! $(grep -Eis '^\s*Banner\s+"?none\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^Banner' /etc/ssh/sshd_config) ]]; then
			echo 'Banner /etc/issue.net' >> /etc/ssh/sshd_config
		else
			sed -i '/^Banner\s\+.\+/c\Banner\s/etc/issue\.net' '/etc/ssh/sshd_config'
		fi
		echo '5.3.18: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:18:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i usepam) =~ yes ]] && [[ ! $(grep -Eis '^\s*UsePAM\s+no' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^UsePAM' /etc/ssh/sshd_config) ]]; then
			echo 'UsePAM yes' >> /etc/ssh/sshd_config
		else
			sed -i '/^UsePAM\s\+.\+/c\UsePAM yes' '/etc/ssh/sshd_config'
		fi
		echo '5.3.19: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:19:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i allowtcpforwarding) =~ no ]] && [[ ! $(grep -Eis '^\s*AllowTcpForwarding\s+yes\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^AllowTcpForwarding' /etc/ssh/sshd_config) ]]; then
			echo 'AllowTcpForwarding no' >> /etc/ssh/sshd_config
		else
			sed -i '/^AllowTcpForwarding\s\+.\+/c\AllowTcpForwarding no' '/etc/ssh/sshd_config'
		fi
		echo '5.3.20: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:20:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i maxstartups) =~ 10:30:60 ]] && [[ ! $(grep -Eis '^\s*maxstartups\s+(((1[1-9]|[1-9][0-9][0-9]+):([0-9]+):([0-9]+))|(([0-9]+):(3[1-9]|[4-9][0-9]|[1-9][0-9][0-9]+):([0-9]+))|(([0-9]+):([0-9]+):(6[1-9]|[7-9][0-9]|[1-9][0-9][0-9]+)))' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^MaxStartups' /etc/ssh/sshd_config) ]]; then
			echo 'MaxStartups 10:30:60' >> /etc/ssh/sshd_config
		else
			sed -i '/^MaxStartups\s\+.\+/c\MaxStartups 10:30:60' '/etc/ssh/sshd_config'
		fi
		echo '5.3.21: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:21:1} = 1 ]]; then
	if [[ $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i maxsessions) =~ [1-10] ]] && [[ ! $(grep -Eis '^\s*MaxSessions\s+(1[1-9]|[2-9][0-9]|[1-9][0-9][0-9]+)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf) ]]; then
		echo "$audit"
	else
		if [[ ! -f 'sshd_config.backup' ]]; then
			cp ' /etc/ssh/sshd_config' 'sshd_config.backup'
			echo '"/etc/ssh/sshd_config" has been backed up to "./sshd_config.backup"'
		fi
		
		if [[ ! $(grep -P '^MaxSessions' /etc/ssh/sshd_config) ]]; then
			echo 'MaxSessions 10' >> /etc/ssh/sshd_config
		else
			sed -i '/^MaxSessions\s\+.\+/c\MaxSessions 10' '/etc/ssh/sshd_config'
		fi
		echo '5.3.22: success'
	fi
fi
echo "$breakpoint"


