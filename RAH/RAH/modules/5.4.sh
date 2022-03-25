#!/bin/bash
# CIS Ubuntu 20.04
# 5.4.1 Ensure password creation requirements are configured (Automated);;;5.4.1: success
# 5.4.2 Ensure lockout for failed password attempts is configured (Automated);;;5.4.2: success
# 5.4.3 Ensure password reuse is limited (Automated);;;5.4.3: success
# 5.4.4 Ensure password hashing algorithm is SHA-512 (Automated);;;5.4.4: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	flag=0
	if (( ! $(grep '^\s*minlen\s*' /etc/security/pwquality.conf) >= 14 )); then
		echo -e 'Password length insufficient. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 432)'
		flag=1
	fi

	if [[ ! $(grep '^\s*minclass\s*' /etc/security/pwquality.conf) =~ 4 ]]; then
		echo -e 'Password complexity insufficient. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 432)'
		flag=1
	fi

	if [[ ! $( grep -E '^\s*password\s+(requisite|required)\s+pam_pwquality\.so\s+(\S+\s+)*retry=[1-3]\s*(\s+\S+\s*)*(\s+#.*)?$' /etc/pam.d/common-password) =~ retry=[0-3] ]]; then
		echo -e 'Password retry attempts too much. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 432)'
		flag=1
	fi
	if [[ $flag=1 ]]; then echo "$wr_p"; else echo "$audit"; fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	flag=0
	## <= Debian 10
	if (( $(lsb_release -a 2>/dev/null | grep 'Release' | grep -oP [0-9]+) <= 10 )); then
		if [[ ! $(grep "pam_tally2" /etc/pam.d/common-auth) ]]; then
			echo -e '(Debian <=10) Password lockouts unconfigured. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 434)'
			flag=1
		fi
		if [[ ! $(grep -E "pam_tally2\.so" /etc/pam.d/common-account) ]]; then
			echo -e '(Debian <=10) pam_tally2.so not included in /etc/pam.d/common-account. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 434)'
			flag=1
		fi
	## >= Debian 11
	else
		if [[ ! $(grep "pam_faillock" /etc/pam.d/common-auth) ]]; then
			echo -e '(Debian 11+) Password lockouts unconfigured. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 434)'
			flag=1
		fi
		if [[ ! $(grep -E "pam_faillock\.so" /etc/pam.d/common-account) ]]; then
			echo -e '(Debian 11+) pam_faillock.so not included in /etc/pam.d/common-account. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 434)'
			flag=1
		fi
	fi

	if [[ ! $(grep -E "pam_deny\.so" /etc/pam.d/common-account) ]]; then
		echo -e 'pam_deny.so not included in /etc/pam.d/common-account. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 434)'
		flag=1
	fi
	
	if [[ $flag=1 ]]; then echo "$wr_p"; else echo "$audit"; fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	echo -e 'Disabled by creator for compatibility reasons'
	echo "$wr_p"
	#if (( $(grep -E '^\s*password\s+required\s+pam_pwhistory\.so\s+([^#]+\s+)?remember=([5-9]|[1-9][0-9]+)\b' /etc/pam.d/common-password 2>/dev/null | grep -oP remember=[0-9]+) >= 5 )); then
	#	echo "$audit"
	#else
	#	echo -e 'Remember last used passwords is fewer than 5. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 434)'
	#fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	flag=0
	## <= Debian 10
	if (( $(lsb_release -a 2>/dev/null | grep 'Release' | grep -oP [0-9]+) <= 10 )); then
		if [[ $(grep -E '^\s*password\s+(\[success=1\s+default=ignore\]|required)\s+pam_unix\.so\s+([^#]+\s+)?sha512\b' /etc/pam.d/common-password | grep sha512) ]]; then
			echo -e '(Debian <=10) Default password hashing algorithm is not 'SHA-512'. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 436)'
		fi
	## >= Debian 11
	else
		if [[ $(grep -E '^\s*password\s+(\[success=1\s+default=ignore\]|required)\s+pam_unix\.so\s+([^#]+\s+)?sha512\b' /etc/pam.d/common-password | grep yescrypt) ]]; then
			echo -e '(Debian 11+) Default password hashing algorithm is not 'Yescrypt'. \nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 436)'
		fi
	fi
	if [[ $flag=1 ]]; then echo "$wr_p"; else echo "$audit"; fi
fi
echo "$breakpoint"

