#!/bin/bash

### Initialization ###
export script_dir="$(realpath $(dirname $0))"
og_user="$(logname)"
python=$(if [[ `python -V 2>&1` == "Python 2.*" ]]; then echo 'python'; else echo 'python3'; fi)




### CONFIGURABLE OPTIONS, ignored if blank/commented ###
# usersinfo.sh #
declare -A checklist=(
	# For validating specific files in each user's directory, requires the 'Others' permissions' bits and the target files. Can add multiple lines per perm.
	# Each file listed here would be checked for in EVERY user's directory
	# Format: ["---"]="filename1 file_name2 .*_wildcard_file" #
	["---"]=".*_history .ssh .Xauthority .ICEauthority .xsession-errors* .wget-hsts .my.cnf .forward"
	["r--"]=".*_logout .*rc .profile"
)


# privinfo.sh #
declare -A priv_checklist=(
	# For validating specific files in the WHOLE drive, requires the requires the 'Others' permissions' bits and the target files's absolute pathing. Can add multiple lines per perm.
	# Each file listed here must have an ABSOLUTE FILE PATH. FILES only.
	# Format: ["---"]="filename1 file_name2 .*_wildcard_file" #
	["---"]="/etc/shadow /etc/sudoers /etc/crontab"
	["r--"]="/etc/passwd /etc/group /etc/profile /etc/fstab"
)
declare -A folderlist=(
	# Same as above, but for FOLDERS only. Non-recursive to prevent output spammming.
	# Format: ["---"]="foldername1 folder_name2 .*_wildcard_folder" #
	["---"]="/etc/cron.d"
	["r--"]="/var/log"
)
sudoers_flags=(
	# Keywords to look out for in '/etc/sudoers'. If these keywords are found, the corresponding entry will be returned.
	# Format:
	#'What to Flag #1' 'What to Flag #2'
	#'What to Flag #3'
	'NOPASSWD:'
)


# piscripts.sh #
export PASSWD_SRC="$script_dir/lists/passwords.txt"
	# Listing the path to the 'passwords' wordlist for Password Hash Breaking
export PKG_SRC="$script_dir/lists/packages.txt"
	# Listing the path to the 'packages' wordlist for checking Package installations




######################

### Menu - HELP ###
Help() {
	echo "PISCES RAT: Collection of modular scripts to enmuerate (Raspberry) Pi system configurations, test and output results. No option requires an input."
	echo "Syntax: _launcher.sh [-h|v|o|H] [-o|u|p|s]" && echo ""
	echo "h      Displays this help text"
	echo "O      Saves output into the relative 'reports' directory"
	echo "[Optional] Choose which scripts to run (chainable, eg -op):"
	echo "o      Enable OS-related enumeration scripts, disabled by default"
	echo "u      Enable scanning of User-related areas"
	echo "p      Enable scanning in certain privileged files"
	echo "s      Enable Pi-specific scanning scripts, made by me"
	echo "a      Activates ALL the above options ('oups' only)"
}
############

### Menu - Arguments ###
while getopts ":haoupsvOH" option; do
	case $option in
		h) # Help
			Help
			exit
			;;
		
		a) # All
			filters+=1
			echo "[INFORMATION] Enabled all filters"
			;;
		o) # OS
			filters+=2
			echo "[INFORMATION] OS-related scripts on"
			;;
		u) # User-related scripts only
			filters+=3
			echo "[INFORMATION] User-related scripts on"
			;;
		p) # Heavier Privileged-area scripts
			filters+=4
			echo "[INFORMATION] Heavier Privileged scripts on"
			;;
		s) # Additional scanning
			filters+=5
			echo "[INFORMATION] Additional scripts on"
			;;
		
		O) # Output to file
			save_as_report=1
			echo "[INFORMATION] Report-saving enabled"
			;;
		\?) # Catch errors
			#echo "Usage: cmd [-h] [-v] [-o] [-H]"
			Help
			exit
			;;
	esac
done
#################
cd $script_dir
chmod +x ./scripts/*.sh
chmod +x ./scripts/*.py
chmod +x ./scripts/html_templating/template.py

### Sources and variables ###
source $script_dir/scripts/osinfo.sh
source $script_dir/scripts/usersinfo.sh
source $script_dir/scripts/privinfo.sh
source $script_dir/scripts/piscripts.sh

#############################


### Sudo check ###
if [ "$EUID" -ne 0 ]
	then echo "[Error] Please run as root"
	exit
fi
##################

### Functions list to be compiled ###
oldIFS=$IFS IFS=$'\n'
os_lst=(
	'get_osinfo'
	'get_networkinfo'
	'get_filesystem'
	'get_cron'
	'get_displays'
	'get_languages'
	'get_envvar'
)
ur_lst=(
	'return_allusers'
	'test_userdir'
	'check_defaultUsers'
	'check_directory_rootowner'
)
pv_lst=(
	'check_privileged'
	'check_privfiles'
)
xr_lst=(
	'checkSetPasswords'
	'checkRecommendedPackages'
	'checkRecommendedPackages_configs'
	'gui_automount'
	'gui_display'
	'audio_output'
	'apparmor_raspbian'
	'startup_mode'
	'pi_services_interfaces'
)
IFS=$oldIFS

if [[ ! $filters ]]; then
	program_lst=(${ur_lst[@]} ${pv_lst[@]} ${xr_lst[@]})
else
	if [[ $filters = *'1'* ]]; then
		program_lst=(${os_lst[@]} ${ur_lst[@]} ${pv_lst[@]} ${xr_lst[@]})
	else
		#echo "[PROC] filters=$filters"
		if [[ $filters == *'2'* ]]; then final_lst+=(${os_lst[@]}); fi
		if [[ $filters == *'3'* ]]; then final_lst+=(${ur_lst[@]}); fi
		if [[ $filters == *'4'* ]]; then final_lst+=(${pv_lst[@]}); fi
		if [[ $filters == *'5'* ]]; then final_lst+=(${xr_lst[@]}); fi
		
		if [[ $final_lst ]]; then program_lst=(${final_lst[@]}); fi
	fi
fi
#####################################

### Program ###
program() {
	if [[ $save_as_report ]]; then
		cmd_length=${#program_lst[@]} cmd_progression=$(printf %.2f $(echo "100/$cmd_length" | bc) && echo "") cmd_counter_ext=0 timestamp=$(date '+%Y-%m-%d_%H%M-%S')
		mkdir -p "$script_dir/reports/$timestamp" 2>/dev/null
		report_name="$script_dir/reports/$timestamp/RAT_$timestamp.txt"
		touch "$report_name" && chown "$og_user:$og_user" "$report_name"
		
		for cmd in ${program_lst[@]}; do
			## Loading bar
			echo -ne "$(head -c $cmd_counter_ext < /dev/zero | tr '\0' '\52') ($cmd_progression%)\r"
			cmd_progression=$(printf %.1f $(echo "100/$cmd_length+$cmd_progression" | bc))
			(( cmd_counter_ext += 1 ))
			
			$cmd >> $report_name
			echo '' >> $report_name
		done
		
		`$python $script_dir/scripts/html_templating/template.py $report_name $script_dir "$og_user ($(id -u $og_user))"`
		if [[ -f "$script_dir"'/scripts/html_templating/templates/RAT.html' ]]; then
			mv "$script_dir/scripts/html_templating/templates/RAT.html" "$script_dir/reports/$timestamp/RAT_$timestamp.html"
		fi
		chown -R "$og_user:$og_user" "$script_dir/reports"
		
		echo '[INFORMATION] Report saved to '"$script_dir/reports/$timestamp"
	else
		for cmd in ${program_lst[@]}; do
			$cmd; echo ''
		done
	fi
	
	echo '[END] RAT execution complete'
}

program
###############
