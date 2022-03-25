#!/bin/bash
declare -a users
declare -A test_userdir_results
longest_name_len=0
oldIFS=$IFS

get_users() {
	### Get user entry from etc/passwd, store into array

	## Check if a user is supplied
	if [[ ! -z "$1" ]]; then
		echo $(cat /etc/passwd | grep "$1")
	else
		## Regex to filter to actual users
		regex=":(/usr/sbin/nologin|/bin/false|/bin/sync|/sbin/nologin)$"
		IFS=$'\n'
		for line in $(cat /etc/passwd | egrep -v $regex); do
			
			### Checks for :: which breaks syntax
			temp_counter=0 temp_index=0 index_ls=( "username" "password" "UID" "GID" ",,," "homedir" "shell" ) if_name_len=1

			count=0
			while (( $count < ${#line} )); do
				if [[ ${line:$count:1} == ":" ]]; then
					if [[ $if_name_len = 1 ]]; then
						if (( $count > $longest_name_len )); then longest_name_len=$count; fi
						if_name_len=0
					fi

					if [[ $temp_counter != $count ]]; then
						between="${line:$(( $temp_counter )):$(( $count-$temp_counter ))}"
						if [[ "$between" == ":" ]]; then
							### Processing for ::
							echo "[INFORMATION] An entry's GECOS in '/etc/passwd' is empty, replacing with ',,,' for now"
							line="${line::$temp_counter+1}${index_ls[$temp_index]}${line:$temp_counter+1}"
						elif [[ "$between" =~ " " ]]; then
							### Processing for space in between strings
							echo "[INFORMATION] An entry's GECOS in '/etc/passwd' contains spaces, replacing with '_' for now"
							between=$(echo $between | tr ' ' '_')
							line="${line::$temp_counter}""$between""${line:$(( $temp_counter+${#between} ))}"
							#echo "PROC ${line::$temp_counter}""$between"" ~~ ${og_line:$(( $temp_counter+${#between} ))}" 
							#echo $line && exit
						fi
					fi
					(( temp_index+=1 ))
					temp_counter=$count
				fi
				(( count+=1 ))
			done
			
			users+=("$line")
		done
		IFS=$oldIFS
	fi
	
	## Debug
	#echo "[DEBUG] ${#users[@]} items in array"
	#for item in ${users[@]}; do
	#	echo "[DEBUG] $item"
	#done
	#exit
}
### Additional processing
get_users

handler_get_user() {
	### Format entries made by get_users() into arrays
	returned=() target=""
	for entry in ${users[@]}; do
		#if [[ ${entry%:*:*:*:*:*:*} == "$1" ]]; then
		if [[ $(cut -d ':' -f1 <<< $entry) == "$1" ]]; then
			target=$entry
			break
		fi
	done

	for value in $(echo $target | tr ":" "\n"); do
		returned+=("$value")
	done
	# Return output
	echo ${returned[@]}
}

handler_get_usernames() {
	returned=()
	for entry in ${users[@]}; do
		returned+=("$(cut -d ':' -f1 <<< $entry)")
	done
	# Return output
	echo ${returned[@]}
}

return_allusers() {
	### Print all valid users and their info
	echo "=== Identified users ==="
	echo '- Users with valid shells -'
	column -t <<< $(echo "Username UID GID Directory Shell"
	for user in ${users[@]}; do
		t=($(echo $user | tr ":" " ") )
		echo "${t[0]} ${t[2]} ${t[3]} ${t[5]} ${t[6]} "
	done)
	
	echo '- Groups memberships -'
	column -t <<< $(echo "Username Groups"
	declare -A g3
	for user in ${users[@]}; do
		t=($(echo $user | tr ":" " ") )
		g=($(groups ${t[0]})) g2=''
		for i in $(seq 0 $(( ${#g[@]}-1 ))); do
			if (( $i > 1 )); then
				g2+="${g[$i]}:$(getent group ${g[$i]} | cut -d: -f3) "
			fi
		done
		g3["${t[0]}"]=$g2
		#echo "${t[0]} ${g[@]:2}"
	done
	for user in ${!g3[@]}; do
		echo "$user ${g3[$user]}"
	done)
}

test_userdir() {
	### Check in home directories for user-specific files (eg history, ssh, etc)
	if [[ ! ${checklist[@]} ]]; then
		declare -A checklist=(
			["---"]=".*_history .ssh .Xauthority .ICEauthority .xsession-errors* .wget-hsts .my.cnf .forward"
			["r--"]=".*_logout .*rc .profile"
		)
	fi
	echo "=== Checking permissions for all non-system users' directories ==="
	
	if [[ -z $1 ]]; then
		## Every user search
		
		## Fetch all usernames to collect all home directories
		usernames=($(handler_get_usernames))
		homedirs=()
		for entry in ${usernames[@]}; do
			user_array=($(handler_get_user $entry))
			homedirs+=(${user_array[5]})
		done
		
		## For a homedir in home_directories
		for target_homedir in ${homedirs[@]}; do
			## Ensure ls is not blank before continuing
			ls_results=$(ls -al "$target_homedir" 2>/dev/null)
			if [[ -z $ls_results ]]; then
				continue
				echo "[WARNING] A user does not have a home directory: $target_homedir"
			fi				

			## For a permissionlist in permlist
			for permlist in ${!checklist[@]}; do
				files_array=(${checklist[$permlist]})
				
				## For a file in checklist
				for file in ${files_array[@]}; do
					#temp=$(stat -c "%A %U %G" $target_homedir/$file 2>/dev/null)
					IFS=$'\n'; temp=($(stat -c "%A %U %G %n" $target_homedir/$file 2>/dev/null))
					if [[ ${#temp[@]} > 1 ]]; then
						for found_result in ${temp[@]}; do
							IFS=$oldIFS; temp_array=($found_result)
							test_userdir_results["$target_homedir;;$permlist;;$(basename ${temp_array[-1]})"]=${temp_array[@]::3}
						done
					else
						test_userdir_results["$target_homedir;;$permlist;;$file"]=${temp[0]}
						IFS=$oldIFS
					fi
					#test_userdir_results["$target_homedir;;$permlist;;$file"]=${temp[0]}
				done
			done
		done
	else
		## Single user search
		target_homedir=($(handler_get_user $1))
		target_homedir=${target_homedir[5]}
		ls_results=$(ls -al "$target_homedir")
		if [[ -z $ls_results ]]; then
			continue
		fi
		
		for permlist in ${!checklist[@]}; do
			files_array=(${checklist[$permlist]})
			
			for file in ${files_array[@]}; do
				temp=$(stat -c "%A %U %G" $target_homedir/$file 2>/dev/null)
				test_userdir_results["$target_homedir;;$permlist;;$file"]=$temp
			done
		done
	fi

	## Return results
	if [[ ! -z ${test_userdir_results[@]} ]]; then
		results_pre=$(for result in ${!test_userdir_results[@]}; do
			#echo [DEBUG] $result ${test_userdir_results[$result]}
			#continue
			if [[ $test_userdir_results[$result]} ]]; then
				temp=($(echo "$result" | tr ";;" " "))
				temp2=(${test_userdir_results[$result]})
				
				if [[ ${temp[1]} == ${temp2[0]:7:3} ]]; then
					temp_check="FOUND,GOOD"
				elif [[ -z ${temp2[0]} ]]; then
					temp_check="MISSING"
				else
					temp_check="FOUND,BAD"
				fi
			fi
			echo "${temp[0]}/${temp[2]};;${temp[1]};;${temp2[0]};;$temp_check"
		done | sort)
		
		persistent_dir=""
		column -t <<< $(for line in ${results_pre[@]}; do
			tline=($(echo $line | tr ";;" " "))
			if [[ -z "$persistent_dir" ]] || [[ "$persistent_dir" != "$(dirname ${tline[0]})" ]]; then
				persistent_dir=$(dirname ${tline[0]})
				#echo "-----Directory: $persistent_dir"
				echo "- Directory: $persistent_dir -"
				echo "FILE COMPLIANCE RECMD(O) DETECTED"
			fi
			
			if [[ ${#tline[@]} == 4 ]]; then
				echo "$(basename $tline) ${tline[3]} ${tline[1]} ${tline[2]}"
			else
				echo "$(basename $tline) ${tline[2]} ${tline[1]}"
			fi
		done)
	fi
}

handler_check_authority() {
	### Check if input (username) is privileged
	target=($(handler_get_user $1))
	pattern="User ${target[0]} is not allowed to run sudo on $(hostname)."

	if [[ ${target[2]} = 0 ]]; then
		## UID 0 means root, should be privileged
		echo True
	elif [[ $(sudo -l -U "${target[0]}" 2>/dev/null) = $pattern ]]; then
		## Checking sudoers for this user, should be not privileged
		echo False
	else
		echo True
	fi
}

check_defaultUsers() {
	### Check if default Raspbian user 'pi' and 'root' have been disabled
	echo "=== Checking if default users are locked ==="
	defaultUsers=('root' 'pi') violatorUsers=() disabledUsers=() deletedUsers=() loginshell=() homedir=()
	echo "- Default Users: ${defaultUsers[@]} -"
	for user in ${defaultUsers[@]}; do
		if [[ $(cat /etc/shadow | grep -P ^$user:) ]]; then
			if [[ $(cat /etc/shadow | grep -P ^$user:!) ]]; then
				disabledUsers+=($user)
			else
				violatorUsers+=($user)
			fi
		else
			deletedUsers+=($user)
		fi
		
		
		if [[ $user != 'root' ]] && [[ $(cat /etc/passwd | grep -P ^$user:) ]]; then
			passwd_entry=($(cat /etc/passwd | grep -P ^$user: | tr ':' ' '))
			if [[ ! ${passwd_entry[-1]} = */false ]] && [[ ! ${passwd_entry[-1]} = */nologin ]]; then
				loginshell+=("$user ${passwd_entry[-1]}")
			fi
			
			if [[ ${passwd_entry[-2]} = /home/* ]]; then
				if [[ -d ${passwd_entry[-2]} ]]; then
					homedir+=("$user ${passwd_entry[-2]} Exists")
				else
					homedir+=("$user ${passwd_entry[-2]}")
				fi
			fi
		fi
	done
	
	if [[ ${violatorUsers[@]} ]]; then
		column -t <<< $(
		IFS=$'\n'
		if [[ ${violatorUsers[@]} ]]; then
			echo 'PASSWORD_LOGIN:'; for item in ${violatorUsers[@]}; do echo "|---$item"; done
		fi
		if [[ ${disabledUsers[@]} ]]; then
			echo 'Disabled:'; for item in ${disabledUsers[@]}; do echo "|---$item"; done
		fi
		if [[ ${deletedUsers[@]} ]]; then
			echo 'Deleted:'; for item in ${deletedUsers[@]}; do echo "|---$item"; done
		fi
		if [[ ${loginshell[@]} ]]; then
			echo 'VALID_SHELLS:'; for item in ${loginshell[@]}; do echo "|---$item"; done
		fi
		if [[ ${homedir[@]} ]]; then
			echo 'VALID_DIRECTORIES:'; for item in ${homedir[@]}; do echo "|---$item"; done
		fi
		)
		if [[ -z ${violatorUsers[@]} ]]; then
			echo 'ALL DEFAULT USERS ARE SECURE!!!'
		fi
		IFS=$oldIFS
	fi
}

check_directory_rootowner() {
	### Check if there are any files in each user directory owned by root
	## Things to look out for:
	# SUID, SGID, Owned by privileged users (eg root, sudo users)
	# Note file extensions (config/cfg could be sensitive, txt/img could be useless)
	echo "=== Searching for non-owner's files in homes ==="
	og_directory=$(pwd)
	for user in ${users[@]}; do
		target=($(echo $user | tr ':' ' '))
		if [[ -d ${target[-2]} ]]; then
			echo "- ${target[0]} (${target[-2]}) -"
			cd ${target[-2]}
			IFS=$'\n', files_owned_by_others=($(find . ! -user ${target[0]} -printf '%M %u %g %P\n'))
			for file in ${files_owned_by_others[@]}; do
				echo $file
			done
			IFS=$oldIFS
		fi
	done
	cd $og_directory
}

#handler_get_user pi
#handler_get_usernames
#test_userdir