#!/bin/bash

### Initialization ###
export script_dir="$(realpath $(dirname $0))"
og_user="$(logname)"
python=$(if [[ `python -V 2>&1` == "Python 2.*" ]]; then echo 'python'; else echo 'python3'; fi)
######################

### HELP ###
Help() {
	echo 'PISCES RAH: A fully automated hardening script using scripts. Existing worldlists are based on the CIS Benchmark for Ubuntu 20.04 and additional Raspberry Pi OS ones. By default, a web server will be launched for customizing options.'
	echo 'Syntax: _launcher.sh [-h|-n|-p <port>]' && echo ''
	echo 'h      Displays this help text'
	echo 'n      For no Desktop, this opens a Whiptail interface via the CLI.'
	echo 'p      Sets a custom Port Number for the HTTP Server. Default is 5000.'
}
############
while getopts "hnp:" option; do
	case $option in
		h) # Help
			Help
			exit
			;;
		n) # No GUI
			nogui=1
			;;
		p) # Port Number
			if (( ${OPTARG} > 0 )) && (( ${OPTARG} < 65536 )); then
				port=${OPTARG}
			else
				echo "Usage: ./_launcher.sh [-h|-n|-p <port>]"
				exit
			fi
			;;
		\?) # Catch errors
			echo "Usage: ./_launcher.sh [-h|-n|-p <port>]"
			exit
			;;
	esac
done
############

### PROGRAM ###
cd $script_dir
chmod +x ./modules/*.sh
chmod +x ./mechanism/*.py
chmod +x ./mechanism/web_server/*.py

`$python ./mechanism/build_config.py`

if [[ ! $nogui ]]; then
	if [[ ! $port ]]; then port=5000; fi
	echo "Starting local web server (http://127.0.0.1:$port)"; web_server=$($python ./mechanism/web_server/web_server.py $port 2>/dev/null)
else
	prompt=$(bash -c "$($python ./mechanism/cli_gui.py 2>/dev/null)")
	`$python ./mechanism/cli_gui.py 2>/dev/null $prompt` 2>/dev/null
	[[ $? = 127 ]] && exit
fi
echo -e "\e[1;36mReceived ... Loading $(grep -P '^\s+true' './mechanism/config.json' | wc -l) configurations\nBeginning execution...\e[0m"

declare -A summary=( ['Audit_passed']=0 ['Success']=0 ['Fail']=0 ['Write-Protection_Triggered']=0 ['Ran_in_Background']='' )
declare -A codes=( ['Audit_passed']='\e[1;36m' ['Success']='\e[1;32m' ['Fail']='\e[41m' ['Write-Protection_Triggered']='\e[41m' ['Ran_in_Background']='\e[1;33m' )
declare -A background_lst=()
declare -A fail_wp_lst=()
oldIFS=$IFS IFS=$'\n'
for script in $(ls './modules' | sort -V | grep -E '.+\.sh$'); do
	results="$($python ./mechanism/mechanism.py $script)"
	
	# Check if result is backgrounded
	if [[ $(echo "$results" | rev | cut -d ' ' -f 1 | rev) =~ ^([a-zA-Z0-9]+\.)+[a-zA-Z0-9]~~~[0-9]+$ ]]; then
		splice=$(echo $results | rev | cut -d ' ' -f 1 | rev)
		results=${results:: -${#splice}}
		background_lst["$(echo "$splice" | cut -d '~' -f 1)"]+="$(echo "$splice" | cut -d '~' -f 4)"
		## Listener for AIDE (and possible future cases))
		tail -f /proc/"$(echo "$splice" | cut -d '~' -f 4)"/fd/1 &>"./$(echo "$splice" | cut -d '~' -f 4).log" &
	elif [[ $(echo "$results" | grep  -P ' : (Fail|Write-Protection Triggered)') ]]; then
		result_lst=($(echo -e "$results"))
		for line in ${result_lst[@]}; do
			if [[ $(echo $line | grep -P ' : (Fail|Write-Protection Triggered)') ]]; then
				fail_wp_lst[$(echo $line | cut -d ' ' -f 1)]="$(echo $line | rev | cut -d ':' -f 1 | rev | xargs)"
			fi
		done
	fi
	
	# Track for summary
	for status_msg in ${!summary[@]}; do
		if [[ $(echo -e "$results" | grep -i " : $(echo $status_msg | tr '_' ' ')") ]]; then
			summary[$status_msg]=$(( ${summary[$status_msg]} + $(echo -e "$results" | grep -i " : $(echo $status_msg | tr '_' ' ')" | wc -l) ))
		fi
	done
	
	# Return results
	[[ $results ]] && echo -e "$results";
done; IFS=$oldIFS

# Dumps stuff
report_folder="$script_dir/reports/$(date '+%Y-%m-%d_%H%M-%S')"
mkdir -p $report_folder/backups
find "$script_dir/reports" -maxdepth 1 -name "*.json" -exec mv '{}' "$report_folder" \;
find "$script_dir/mechanism" -maxdepth 1 -name "*.backup" -exec mv '{}' "$report_folder/backups" \;
chown -R "$og_user:$og_user" "$report_folder"

IFS=$oldIFS
arrangement=('Audit_passed' 'Success' 'Fail' 'Write-Protection_Triggered' 'Ran_in_Background')
echo -e "\nSummary:"; for key in ${arrangement[@]}; do echo -e "${codes[$key]}$key: ${summary[$key]}\e[0m"; done

if [[ ${fail_wp_lst[@]} ]]; then
	prefix="${codes['Fail']}"
	echo -e '\n'"$prefix""${#fail_wp_lst[@]} module(s) require your attention. Please review their outputs manually.\e[0m"
	IFS=$'\n'
	(for module in ${!fail_wp_lst[@]}; do echo -e "$prefix""$module : ${fail_wp_lst[$module]}\e[0m"; done) | sort -V
	IFS=$oldIFS
fi

if [[ ! ${background_lst[@]} ]]; then
	echo -e "\n\e[1;36m[END]Execution complete, refer to $report_folder to review the script outputs\nRESTART to apply the patches.\e[0m"
else
	prefix="${codes['Ran_in_Background']}"
	echo -e '\n'"$prefix""Execution almost complete, ${#background_lst[@]} module(s) are still running in the background:\e[0m"
	PIDs=()
	msg=()
	for entry in ${!background_lst[@]}; do
		msg+=("$entry\_${background_lst[$entry]}")
		PIDs+=("${background_lst[$entry]}")
	done
	column -t <<< $(echo -e "$prefix"'Module_PID\e[0m' | tr '\\_' ' '; (for line in ${msg[@]}; do echo -e "$prefix""$line\e[0m"; done) | tr '\\_' ' ' | sort -V)
	temp=$(column -t <<< $(echo 'Module PID'; (for line in ${msg[@]}; do echo "$line" | tr '\\_' ' '; done) | sort -V) | tr '\n' '~')
	random=$RANDOM
	
	sleep 2
	watch -x /bin/bash -c "bullseye=$random; (echo '${temp[@]}' | tr '~' '\n'); echo; ps p '$(echo ${PIDs[@]})' || (ps aux | grep watch | grep $random | awk '{print \$2}' | xargs kill)"
	echo -e '\n\e[1;36m[END] All background modules are done. Please RESTART FIRST, some flagged modules might be resolved this way.\e[0m'
fi

