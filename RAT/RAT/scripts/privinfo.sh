#!/bin/bash
declare -A test_privileged_results
declare -A check_privfiles_results

check_privileged() {
	### Check permissions to privileged files
	echo "=== Checking permissions on system files ==="
	echo '- Permissions -'
	
	if [[ ! ${priv_checklist[@]} ]]; then
		declare -A priv_checklist=(
			["---"]="/etc/shadow /etc/sudoers /etc/crontab"
			["r--"]="/etc/passwd /etc/group /etc/profile /etc/fstab"
		)
	fi
	if [[ ! ${folderlist[@]} ]]; then
		declare -A folderlist=(
			["---"]="/etc/cron.d"
			["r--"]="/var/log"
		)
	fi
	
	for perm in ${!priv_checklist[@]}; do
		for target in ${priv_checklist[$perm]}; do
			#echo $(stat -c "%A %U %G %n" $target)
			test_privileged_results["priv;;$perm;;$target"]=$(stat -c "%A %U %G %n" $target 2>/dev/null)
		done
	done
	### Check permissions on privileged folders (non-recursive)
	for folder_perm in ${!folderlist[@]}; do
		for folder in ${folderlist[$folder_perm]}; do
			test_privileged_results["privfolder;;$folder_perm;;$folder"]=$(stat -c "%A %U %G %n" $folder 2>/dev/null)
		done
	done

	## Return results
	if [[ ! -z ${test_privileged_results[@]} ]]; then
		results=$(for result in ${!test_privileged_results[@]}; do
			echo "$result;;$(echo ${test_privileged_results[$result]} | tr " " ";;")"
		done | sort)
		column -t <<< $(echo "FILE COMPLIANCE RECMD(O) DETECTED"
		for line in ${results[@]}; do
			tline=($(echo $line | tr ";;" " "))
			
			if [[ ${tline[1]} == ${tline[3]:7:3} ]]; then
				temp_check="GOOD"
			else
				temp_check="BAD"
			fi
			
			echo "${tline[2]} $temp_check ${tline[1]} ${tline[3]}"
		done)
	fi
}

check_privfiles() {
	### Check certain files
	echo "=== Checking sensitive system files ==="
	passwd_array="" shadow_array=() sudoers_array="" sudoers_includedir=()
	usernames_lst=($(handler_get_usernames)) oldIFS=$IFS
	
	
	local IFS=$'\n'
	## 1. Check if any plaintext/weak encrypted passwords are stored in /etc/shadow
	## 	Ensure root is locked (ie 2nd field is "!")
	## 	Get all usernames of actual users
	## 	Check if all above users are using SHA-512/yescrypt
	shadow_ls=($(cat /etc/shadow)) IFS=$oldIFS
	for line in ${shadow_ls[@]}; do
		for username in ${usernames_lst[@]}; do
			temp=$(echo $line | egrep "^$username") temp2=()
			if [[ $temp ]]; then
				shadow_array+=("$(echo $temp | cut -d ":" -f 1-2)")
			fi
		done
	done
	IFS=$oldIFS
	
	echo '- /etc/shadow entries -'
	column -t <<< $(
	echo 'USERNAME ALGORITHM HASH';
	declare -A algos=(
		['1']='MD5' 
		['2a']='Blowfish'
		['2b']='Bcrypt'
		['2y']='Blowfish'
		['3']='NT'
		['5']='SHA-256'
		['6']='SHA-512'
		['7']='Scrypt'
		['y']='Yescrypt'
		['gy']='Gost-Yescrypt'
	)
	declare -A debian_versions=(
		['10']='6'
		['11']='y'
	)
	for entry in ${shadow_array[@]}; do
		temp=($( echo $entry | tr ':' ' ' ))
		if [[ "$entry" =~ ^${temp[0]}:\! ]] || [[ "$entry" =~ ^${temp[0]}:\* ]]; then
			echo "${temp[0]} LOCKED"
		elif [[ "${temp[1]}" =~ ^\$([13567]|2[aby]|y|gy)\$ ]]; then
			t=$(echo ${temp[1]} | tr '$' ' ' | awk '{print $1}')
			default=${debian_versions[$(cat /etc/os-release | grep VERSION_ID= | egrep -o '".+"' | awk '{print substr($1, 2, length($1)-2)}')]}
			if [[ $default == $t ]]; then
				echo "${temp[0]} ${algos[$t]}(Default)"
			else
				echo "${temp[0]} ${algos[$t]}"
			fi
		elif [[ "${temp[1]}" =~ \$[0-9a-zA-Z]+\$ ]]; then
			echo "${temp[0]} UNKNOWN ${temp[1]}"
		else
			echo "${temp[0]} NIL ${temp[1]}"
		fi
	done
	) && echo
	
	
	## 2. Read sudoers and its related files' contents
	##	Ensure the correct "Defaults" are set
	##	Ensure NO USER but root has 'NOPASSWD:', can add other flags
	##	Check groups
	##	Check "includedir"
	if [[ ! ${sudoers_flags[@]} ]]; then
		sudoers_flags=('NOPASSWD:')
	fi
	
	dir_list=("/etc/sudoers") last_read_line=""
	declare -i dir_counter=0
	while (( $dir_counter < ${#dir_list[@]} )); do
		IFS=$'\n'
		current=${dir_list[$dir_counter]}
		sudoers_ls=$(cat $current  2>/dev/null | egrep "^([^#]|(#includedir)|(#include))" 2>/dev/null)
		
		if [[ $sudoers_ls ]]; then
		
			## Loop
			for line in ${sudoers_ls[@]}; do
				### Check if need to concat all lines spread over multiple lines FIRST
				if [[ $last_read_line ]]; then
					if [[ ${line: -1} =~ '\' ]]; then
						last_read_line="$(echo $last_read_line | tr -d '\\')""$(echo $line | tr -d '\t')"
						#last_read_line="${last_read_line:: -1}""$(echo ${line:: -1} | tr -d '\t')"
						continue
					else
						### Overwrite loop's variable aka 'line'
						line="$last_read_line""$(echo $line | tr -d '\t')"
						last_read_line=""
					fi
				elif [[ ${line: -1} =~ '\' ]]; then
					last_read_line=$line
					continue
				fi
				
				### Post multi-line check
				for flag in ${sudoers_flags[@]}; do
					if [[ $(echo $line | grep "$flag") ]]; then
						sudoers_array+="${dir_list[$dir_counter]};;$line~~~"
					fi
				done
				
				if [[ $line =~ ^([#@]include) ]]; then
					### Logic to append dir to dir_list
					## #includedir
					if [[ $line =~ ^([#@]includedir) ]]; then
						if [[ ! "$line" =~ / ]]; then
							found="/etc/${line:12}"
						else
							found="${line:12}"
						fi
						lst=($(ls $found/*))
						if [[ lst ]]; then
							dir_list+=(${lst[@]})
						fi
					## #include
					else
						if [[ ! "$line" =~ / ]]; then
							found="/etc/${line:9}"
						else
							found="${line:9}"
						fi
						if [[ -d $found ]]; then
							lst=($(ls $found 2>/dev/null))
							if [[ lst ]]; then
								dir_list+=($found)
							fi
						else
							dir_list+="$found"
						fi
					fi
				
				
				fi
			done
		fi
		
		dir_counter+=1
	done
	check_privfiles_results["sudoers"]=$sudoers_array
	echo "- /etc/sudoers entries -"
	temp_display=''; for source in ${dir_list[@]}; do temp_display+="$source, "; done
	echo "Identified links: ${temp_display::-2}"
	column -t <<< $(
		echo "SOURCE LINE"
		echo $sudoers_array | sed 's/;;/\t/g' | sed 's/~~~/\n/g'
	)
	IFS=$oldIFS
}
