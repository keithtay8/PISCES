#!/bin/bash
# CIS Ubuntu 20.04
# 6.2.1 Ensure accounts in /etc/passwd use shadowed passwords (Automated);;;6.2.1: success
# 6.2.2 Ensure password fields are not empty (Automated);;;6.2.2: success
# 6.2.3 Ensure all groups in /etc/passwd exist in /etc/group (Automated);;;6.2.3: success
# 6.2.4 Ensure all users' home directories exist (Automated);;;6.2.4: success
# 6.2.5 Ensure users own their home directories (Automated);;;6.2.5: success
# 6.2.6 Ensure users' home directories permissions are 750 or more restrictive (Automated);;;6.2.6: success
# 6.2.7 Ensure users' dot files are not group or world writable (Automated);;;6.2.7: success
# 6.2.8 Ensure no users have .netrc files (Automated);;;6.2.8: success
# 6.2.9 Ensure no users have .forward files (Automated);;;6.2.9: success
# 6.2.10 Ensure no users have .rhosts files (Automated);;;6.2.10: success
# 6.2.11 Ensure root is the only UID 0 account (Automated);;;6.2.11: success
# 6.2.12 Ensure root PATH Integrity (Automated);;;6.2.12: success
# 6.2.13 Ensure no duplicate UIDs exist (Automated);;;6.2.13: success
# 6.2.14 Ensure no duplicate GIDs exist (Automated);;;6.2.14: success
# 6.2.15 Ensure no duplicate user names exist (Automated);;;6.2.15: success
# 6.2.16 Ensure no duplicate group names exist (Automated);;;6.2.16: success
# 6.2.17 Ensure shadow group is empty (Automated);;;6.2.17: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	if [[ ! $(awk -F: '($2 != "x" ) { print $1 " is not set to shadowed passwords "}' /etc/passwd) ]]; then
		echo "$audit"
	else
		if [[ ! -f "passwd.backup" ]]; then
			cp "/etc/passwd" "./passwd.backup"
			echo "'/etc/passwd' has been backed up to './passwd.backup'"
		fi
		$(sed -e 's/^\([a-zA-Z0-9_]*\):[^:]*:/\1:x:/' -i /etc/passwd) && echo '6.2.1: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	if [[ ! $(awk -F: '($2 == "" ) { print $1 " does not have a password "}' /etc/shadow) ]]; then
		echo "$audit"
	else
		for username in $(awk -F: '($2 == "" ) { print $1 }' /etc/shadow); do
			bash -c "passwd -l $username"
		done && echo '6.2.2: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	main_audit=$(
	for i in $(cut -s -d: -f4 /etc/passwd | sort -u ); do
		grep -q -P "^.*?:[^:]*:$i:" /etc/group
		if [ $? -ne 0 ]; then
			echo "Group $i is referenced by /etc/passwd but does not exist in /etc/group"
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		echo -e 'Refer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 494)'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	main_audit=$(
	awk -F: '($1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
		if [ ! -d "$dir" ]; then
			echo "User: \"$user\" home directory: \"$dir\" does not exist."
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		awk -F: '($1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
			if [ ! -d "$dir" ]; then
				mkdir "$dir"
				chmod g-w,o-wrx "$dir"
				chown "$user" "$dir"
			fi
		done && echo '6.2.4: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:4:1} = 1 ]]; then
	main_audit=$(
	awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' | while read -r user dir; do
		if [ ! -d "$dir" ]; then
			echo "User: \"$user\" home directory: \"$dir\" does not exist."
	 	else
			owner=$(stat -L -c "%U" "$dir")
			if [ "$owner" != "$user" ]; then
				echo "User: \"$user\" home directory: \"$dir\" is owned by \"$owner\""
			fi
		fi
	done)
	echo 'done'
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' | while read -r user dir; do
			if [ ! -d "$dir" ]; then
				echo "User: \"$user\" home directory: \"$dir\" does not exist, creating home directory"
				mkdir "$dir"
				chmod g-w,o-rwx "$dir"
				chown "$user" "$dir"
			else
				owner=$(stat -L -c "%U" "$dir")
				if [ "$owner" != "$user" ]; then
					chmod g-w,o-rwx "$dir"
					chown "$user" "$dir"
				fi
			fi
		done && echo '6.2.5: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:5:1} = 1 ]]; then
	main_audit=$(
	awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) {print $1 " " $6}' /etc/passwd | while read -r user dir; do
		if [ ! -d "$dir" ]; then
			echo "User: \"$user\" home directory: \"$dir\" doesn't exist"
		else
			dirperm=$(stat -L -c "%A" "$dir")
	 		if [ "$(echo "$dirperm" | cut -c6)" != "-" ] || [ "$(echo "$dirperm" | cut -c8)" != "-" ] || [ "$(echo "$dirperm" | cut -c9)" != "-" ] || [ "$(echo "$dirperm" | cut -c10)" != "-" ]; then
				echo "User: \"$user\" home directory: \"$dir\" has permissions: \"$(stat -L -c "%a" "$dir")\""
			fi
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) {print $6}' /etc/passwd | while read -r dir; do
			if [ -d "$dir" ]; then
				dirperm=$(stat -L -c "%A" "$dir")
				if [ "$(echo "$dirperm" | cut -c6)" != "-" ] || [ "$(echo "$dirperm" | cut -c8)" != "-" ] || [ "$(echo "$dirperm" | cut -c9)" != "-" ] || [ "$(echo "$dirperm" | cut -c10)" != "-" ]; then
					chmod g-w,o-rwx "$dir"
				fi
			fi
		done && echo '6.2.6: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:6:1} = 1 ]]; then
	main_audit=$(
	awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
		if [ -d "$dir" ]; then
			for file in "$dir"/.*; do
				if [ ! -h "$file" ] && [ -f "$file" ]; then
					fileperm=$(stat -L -c "%A" "$file")
					if [ "$(echo "$fileperm" | cut -c6)" != "-" ] || [ "$(echo "$fileperm" | cut -c9)" != "-" ]; then
	 					echo "User: \"$user\" file: \"$file\" has permissions: \"$fileperm\""
					fi
				fi
			done
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' | while read -r user dir; do
			if [ -d "$dir" ]; then
				for file in "$dir"/.*; do
					if [ ! -h "$file" ] && [ -f "$file" ]; then
						fileperm=$(stat -L -c "%A" "$file")
						if [ "$(echo "$fileperm" | cut -c6)" != "-" ] || [ "$(echo "$fileperm" | cut -c9)" != "-" ]; then
							chmod go-w "$file"
						fi
					fi
				done
			fi
		done && echo '6.2.7: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:7:1} = 1 ]]; then
	main_audit=$(
	awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
		if [ -d "$dir" ]; then
			file="$dir/.netrc"
			if [ ! -h "$file" ] && [ -f "$file" ]; then
				if stat -L -c "%A" "$file" | cut -c4-10 | grep -Eq '[^-]+'; then
	 				echo "FAILED: User: \"$user\" file: \"$file\" exists with permissions: \"$(stat -L -c "%a" "$file")\", remove file or excessive permissions"
				else
					echo "WARNING: User: \"$user\" file: \"$file\" exists with permissions: \"$(stat -L -c "%a" "$file")\", remove file unless required"
				fi
			fi
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $6 }' /etc/passwd | while read -r dir; do
			if [ -d "$dir" ]; then
				file="$dir/.netrc"
				[ ! -h "$file" ] && [ -f "$file" ] && rm -f "$file"
			fi
		done && echo '6.2.8: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:8:1} = 1 ]]; then
	main_audit=$(
	awk -F: '($1!~/(root|halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
		if [ -d "$dir" ]; then
			file="$dir/.forward"
			if [ ! -h "$file" ] && [ -f "$file" ]; then
				echo "User: \"$user\" file: \"$file\" exists"
			fi
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		awk -F: '($1!~/(root|halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $6 }' /etc/passwd | while read -r dir; do
			if [ -d "$dir" ]; then
				file="$dir/.forward"
				[ ! -h "$file" ] && [ -f "$file" ] && rm -r "$file"
			fi
		done && echo '6.2.9: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:9:1} = 1 ]]; then
	main_audit=$(
	awk -F: '($1!~/(root|halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
		if [ -d "$dir" ]; then
			file="$dir/.rhosts"
			if [ ! -h "$file" ] && [ -f "$file" ]; then
				echo "User: \"$user\" file: \"$file\" exists"
			fi
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		awk -F: '($1!~/(root|halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $6 }' /etc/passwd | while read -r dir; do
			if [ -d "$dir" ]; then
				file="$dir/.rhosts"
				[ ! -h "$file" ] && [ -f "$file" ] && rm -r "$file"
			fi
		done && echo '6.2.10: success'
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:10:1} = 1 ]]; then
	if [[ $(awk -F: '($3 == 0) { print $1 }' /etc/passwd) = 'root' ]]; then
		echo "$audit"
	else
		echo -e 'Remove any users other than root with UID 0 or assign them a new UID if appropriate.\nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 511)\n'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:11:1} = 1 ]]; then
	main_audit=$(
	RPCV="$(sudo -Hiu root env | grep '^PATH' | cut -d= -f2)"
	echo "$RPCV" | grep -q "::" && echo "root's path contains a empty directory (::)"
	echo "$RPCV" | grep -q ":$" && echo "root's path contains a trailing (:)"
	for x in $(echo "$RPCV" | tr ":" " "); do
		if [ -d "$x" ]; then
			ls -ldH "$x" | awk '$9 == "." {print "PATH contains current working directory (.)"}
			$3 != "root" {print $9, "is not owned by root"}
			substr($1,6,1) != "-" {print $9, "is group writable"}
			substr($1,9,1) != "-" {print $9, "is world writable"}'
		else
			echo "$x is not a directory"
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		echo -e 'Correct or justify any items discovered in the Audit step.\nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 512)'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:12:1} = 1 ]]; then
	main_audit=$(
	cut -f3 -d":" /etc/passwd | sort -n | uniq -c | while read x ; do
		[ -z "$x" ] && break
		set - $x
		if [ $1 -gt 1 ]; then
			users=$(awk -F: '($3 == n) { print $1 }' n=$2 /etc/passwd | xargs)
			echo "Duplicate UID ($2): $users"
		fi
	done)
	if [[ ! $main_audit ]]; then
		echo "$wr_p"
	else
		echo -e 'Based on the results of the audit script, establish unique UIDs and review all files owned by the shared UIDs to determine which UID they are supposed to belong to.\nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 514)'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:13:1} = 1 ]]; then
	main_audit=$(
	cut -d: -f3 /etc/group | sort | uniq -d | while read x ; do
		echo "Duplicate GID ($x) in /etc/group"
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		echo -e 'Based on the results of the audit script, establish unique GIDs and review all files owned by the shared GID to determine which group they are supposed to belong to.\nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 515)'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:14:1} = 1 ]]; then
	main_audit=$(
	cut -d: -f1 /etc/passwd | sort | uniq -d | while read -r x; do
		echo "Duplicate login name $x in /etc/passwd"
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		echo -e 'Based on the results of the audit script, establish unique user names for the users. File ownerships will automatically reflect the change as long as the users have unique UIDs.\nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 516)'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:15:1} = 1 ]]; then
	main_audit=$(
	cut -d: -f1 /etc/group | sort | uniq -d | while read -r x; do
		echo "Duplicate group name $x in /etc/group"
	done)
	if [[ ! $main_audit ]]; then
		echo "$audit"
	else
		echo -e 'Based on the results of the audit script, establish unique names for the user groups. File group ownerships will automatically reflect the change as long as the groups have unique GIDs.\nRefer to the CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0.pdf (Page 517)'
		echo "$wr_p"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:16:1} = 1 ]]; then
	flag=0 flag2=0
	if [[ $(awk -F: '($1=="shadow") {print $NF}' /etc/group) ]]; then flag=1; fi
	if [[ $(awk -F: -v GID="$(awk -F: '($1=="shadow") {print $3}' /etc/group)" '($4==GID) {print $1}' /etc/passwd) ]]; then flag2=1; fi
	if [[ ! $flag = 1 ]] && [[ ! $flag2 = 1 ]]; then
		echo "$audit"
	else
		if [[ $flag = 1 ]]; then
			if [[ ! -f "group.backup" ]]; then
				cp "/etc/group" "./group.backup"
				echo "'/etc/group' has been backed up to './group.backup'"
			fi
			sed -ri 's/(^shadow:[^:]*:[^:]*:)([^:]+$)/\1/' /etc/group
		fi
		if [[ $flag2 = 1 ]]; then
			main_audit=($(awk -F: -v GID="$(awk -F: '($1=="shadow") {print $3}' /etc/group)" '($4==GID) {print $1}' /etc/passwd))
			for username in ${main_audit[@]}; do
				usermod -g "$username" "$username"
			done
		fi
	fi
fi
echo "$breakpoint"