#!/bin/bash

# Initialization from raspi-config
boot_config=/boot/config.txt
deb_version=$(cat /etc/debian_version | cut -d . -f 1)
arch=$(dpkg --print-architecture)

cmdline_location=$(
if [ "$arch" = "armhf" ] || [ "$arch" = "arm64" ] ; then
	echo '/boot/cmdline.txt'
else
	echo '/proc/cmdline'
fi)

whichpi=$(
if [[ $(grep -q "^Revision\s*:\s*00[0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo) ]]||[[ $(grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[0-36][0-9a-fA-F]$" /proc/cpuinfo) ]]; then
	echo 'one'
elif [[ $(grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]04[0-9a-fA-F]$" /proc/cpuinfo) ]]; then
	echo 'two'
elif [[ $(grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[9cC][0-9a-fA-F]$" /proc/cpuinfo) ]]; then
	echo 'zero'
elif [[ $(grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]3[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo) ]]; then
	echo 'four'
else
	echo 'non-pi'
fi)
#

checkSetPasswords() {
	### Get all users' entries from shadow, fetch salt and generate hashes to compare later

	### Check for hashes in /etc/passwd
	IFS=$'\n'
	for line in $(cat /etc/passwd); do
	#for line in $(cat "/home/pi/passwd_test"); do
		result=($(echo $(cut -d ':' -f1,2 <<< $line)| tr ":" "\n"))
		if [[ ${result[1]} != "x" ]]; then
			passwd_array+="${result[0]}::${result[1]};;"
		fi
	done
	export ETC_PASSWD_LST=$passwd_array
	IFS=$oldIFS

	## Get all applicable users from /etc/shadow into an array
	pattern='^[a-zA-Z0-9_-]+[$]?:\$[1,2a,2y,5,6]\$'
	shadow_contents=($(sudo cat /etc/shadow | egrep $pattern)) entries_lst='' internal_counter=0
	for i in ${shadow_contents[@]}; do
		i=($(echo $i | tr ":" " "))
		entries_lst+="${i[0]}::${i[1]};;"
		(( internal_counter+=1 ))
	done
	entries_lst=${entries_lst::-2}
	export PASSWD_LST=$entries_lst
	export PASSWD_SRC="$script_dir/lists/passwords.txt"
	
	result=`python3 $script_dir/scripts/python_pwcheck.py`
	result=($(echo $result | tr ';' ' '))
	
	declare -A nicer_result
	for item in ${result[@]}; do
		spliced=($(echo $item | tr '::' ' ')) keys=(${!nicer_result[@]})
		if [[ ${spliced[1]} ]]; then
			nicer_result[${keys[-1]}]+="$item;"
		else
			nicer_result[${spliced[0]}]=
		fi
	done
	
	echo "=== Checking password hashes against common passwords ==="
	echo '- Cracked passwords -'
	temp_external_counter=0
	for key in ${!nicer_result[@]}; do
		echo $key
		holder=$(
			echo -e '| USERNAME PASSWORD'
			string_lst=($(echo ${nicer_result[$key]} | tr ';;' ' ')) username_counter=0
			for item in ${string_lst[@]}; do
				temp=($(echo $item | tr '::' ' '))
				export username_counter=$(( username_counter+=1 ))
				echo -e "|--- ${temp[0]} ${temp[1]}"
			done
			echo -e "$username_counter"
		)
		local IFS=$'\n'; column -t <<< $(
			echo -e "${holder:: -1}"
		)
		echo && echo "${holder: -1}/$internal_counter user(s)' passwords obtained, compared against list of $(cat $PASSWD_SRC | wc -l) passwords"
		
		if (( $temp_external_counter + 1 < ${#nicer_result[@]} )); then
			(( external_counter+=1 ))
			echo
		fi
	done
}

checkRecommendedPackages() {
	### Check for popular recommended packages for security
	pkg_src="$script_dir/lists/packages.txt" pkg_results_lst=() IFS=$'\n'
	
	if [[ -f $pkg_src ]]; then
	
		installed_pkg_lst=$(dpkg --list)
		for line in $(cat $pkg_src); do
			line=$(echo $line | tr -d '\n')
			if [[ ${line:0:1} == '[' ]] && [[ ${line: -1} == ']' ]]; then
				temp=$(echo $installed_pkg_lst | grep "${line:1:-1}")
				[[ $temp ]]; pkg_results_lst+=("$line::$?")
			fi
		done
		
		echo '=== Checking for certain installed packages ==='
		echo '- Recommended packages -'
		installed_counter=0
		column -t -e <<< $(
			echo 'PACKAGE_NAME INSTALLED'
			for package in ${pkg_results_lst[@]}; do
				pkg_name=${package%::*}
				if [[ ${package: -1} == 0 ]]; then
					echo "${pkg_name:1: -1} TRUE"
					(( installed_counter+=1 ))
				else
					echo "${pkg_name:1: -1} FALSE"
				fi
			done
			echo -e "\n$installed_counter/${#pkg_results_lst[@]} packages installed"
		)
		IFS=$oldIFS
	
	else
		echo "[WARNING-checkRecommendedPackages] $pkg_src is missing, skipping"
	fi
}

checkRecommendedPackages_configs() {
	### Supporting code for my custom API in packages.txt
	export PKG_SRC="$script_dir/lists/packages.txt"
	
	echo "=== Checking certain installed packages' configs ==="
	echo '- Package config scanner results -'
	python3 "$script_dir/scripts/package_txt.py"
}


gui_automount() {
	### Check if every user has automount disabled
	echo '=== GUI USB Automounting ==='
	echo '- Checking if GUI automount is disabled globally -'
	declare -A automount_results
	err_lookup=("pcmanfm.conf_missing" "mount_on_startup" "mount_removable" "autorun")
	for user in ${users[@]}; do
		user_split=($(echo $user | tr ':' ' '))
		if [[ -d "${user_split[-2]}" ]] && [[ -f "${user_split[-2]}/.config/pcmanfm/LXDE-pi/pcmanfm.conf" ]]; then
			for count in $( seq 1 ${#err_lookup[@]} ); do
				temp_result=$(grep "${err_lookup[$count]}" "${user_split[-2]}/.config/pcmanfm/LXDE-pi/pcmanfm.conf" | tr -d "${err_lookup[$count]}=")
				if [[ ! $temp_result = 0 ]]; then
					automount_results["${user_split[0]};${user_split[-2]}"]="${automount_results[${user_split[0]};${user_split[-2]}]};${err_lookup[$count]}"
				fi
			done
		else
			automount_results["${user_split[0]};${user_split[-2]}"]="${err_lookup[0]}"
		fi
	done
	if [[ ${automount_results[@]} ]]; then
		local IFS=$'\n'; column -t <<< $(
		echo 'User Dir Violations'
		for user in ${!automount_results[@]}; do
			if [[ ${automount_results[$user]::1} == ';' ]]; then
				echo "$(echo $user | tr ';' ' ') ${automount_results[$user]}" | tr ';' ' '
			else
				echo "$(echo $user | tr ';' ' ') ${automount_results[$user]}"
			fi
		done
		)
	fi
}

gui_display() {
	### Check if HDMI output is disabled
	checker=(0 0)
	echo '=== Video output checks ==='
	echo '- (Bootloader) OpenGL Driver -'
	temp=($(grep -oP '(?<=^dtoverlay=).+' $boot_config))
	if [[ ${temp[@]} ]]; then
		echo ${temp[-1]}
	else
		echo 'No detected GL Driver'
	fi
	
	echo '- HDMI -'
	vcgencmd_status=$(vcgencmd display_power 2>/dev/null)
	if [[ $vcgencmd_status ]] && [[ $vcgencmd_status = 'display_power=0' ]]; then
		echo 'HDMI is off'
	else
		echo '(!) HDMI is on - Run "vcgencmd display_power=0" at startup via a cronjob, rc.local, etc'
		checker[0]=1
	fi; echo ''
	IFS=$oldIFS
	
	echo '- Composite -'
	IFS=$'\n'; tvservice_status=($(tvservice -s 2>/dev/null))
	echo "Number of displays: ${#tvservice_status[@]}"
	if [[ ${tvservice_status[@]} ]]; then
		for item in ${tvservice_status[@]}; do
			if [[ $(echo $item | grep '[TV is Off]') ]]; then
				echo 'Composite is off'
			else
				echo '(!) Composite is on, Run "tvservice -o" at startup via a cronjob, rc.local, etc'
				checker[1]=1
			fi
		done
	else
		echo '(!) "tvservice" not supported, please manually confirm if composite output is still available. You can also follow the below Recommended solution and rerun the program'
	fi
	echo ''
	
	if [[ ${checker[0]} = 1 ]] || [[ ${checker[1]} = 1 ]]; then
		echo "Recommended solution: Modify '$boot_config' to replace/include 'dtoverlay=vc4-fkms-v3d' (and do the above)"
	fi
}

audio_output() {
	### Check if Audio is enabled
	echo '=== Audio ==='
	echo '- Audio outputs -'
	IFS=$'\n' audio_devices=($(aplay -l 2>/dev/null | grep -P '^card\s'))
	if [[ ${audio_devices[@]} ]]; then
		printf "%s\n" "${audio_devices[@]}"
	else
		echo 'No detected audio devices'
	fi
	IFS=$oldIFS
}

apparmor_raspbian() {
	### Check if AppArmor is enabled in Raspbian's bootloader
	echo '=== AppArmor (Raspbian) ==='
	echo '- Installation Status -'
	aa_install=$(dpkg -s apparmor 2>/dev/null | grep -E '(Status:|not installed)')
	if [[ $aa_install = 'Status: install ok installed' ]]; then
		echo "$aa_install" && echo ''
		echo '- In Bootloader Configuration Status -'
		
		if [[ -f "$cmdline_location" ]]; then
			aa_temp=($(cat "$cmdline_location" | grep -v "apparmor=1") $(cat "$cmdline_location" | grep -v "security=apparmor"))
			if [[ ! ${aa_temp[0]} ]] && [[ ! ${aa_temp[1]} ]]; then
				echo 'Configured at Startup'
			else
				echo "(!)Not configured at Startup, add 'apparmor=1 security=apparmor' to '$cmdline_location'"
			fi
		else
			echo "'$cmdline_location' does not exist, you will need to manually make this to enable at startup."
			echo 'Create the above file and add "apparmor=1 security=apparmor"'
		fi
		echo ''
		echo '- AppArmor Profile Status -'
		apparmor_status | grep profiles
	else
		echo $aa_install
	fi
}

startup_mode() {
	### Checks if autologin is enabled on the system
	echo '=== Startup UI ==='
	echo '- Boot-into mode -'
	if  systemctl get-default | grep -q multi-user; then
		echo 'Booting to CLI by default'
	else
		echo '(!) Booting to Desktop by default, please boot into CLI instead'
	fi
	
	echo '- Auto Login -'
	if [[ -e /etc/systemd/system/getty@tty1.service.d/autologin.conf ]]; then
		if [[ $(grep -P 'ExecStart=.+' /etc/systemd/system/getty@tty1.service.d/autologin.conf) ]]; then
			temp=$(grep -oP '(?<=--autologin\s).+(?=\s--noclear)' /etc/systemd/system/getty@tty1.service.d/autologin.conf)
			echo "(!) CLI as $temp"
		fi
	else
		echo 'CLI: no issues'
	fi
	if [[ -e /etc/lightdm/lightdm.conf ]]; then
		temp=$(grep -oP '(?<=^autologin-user=).+' /etc/lightdm/lightdm.conf)
		if [[ $temp ]]; then
			echo "(!) Desktop GUI as $temp"
		else
			echo 'Desktop GUI: no issues'
		fi
	fi
	
	echo '- Network Boot -'
	if [[ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]]; then
		echo 'Waiting for network on boot: True'
	else
		echo 'Waiting for network on boot: False'
	fi
	
	echo '- Splash Screen -'
	if [[ -e /usr/share/plymouth/themes/pix/pix.script ]] && [[ $(grep -q 'splash' $cmdline_location) ]]; then
		echo '(!) Splash Screen: True'
	else
		echo 'Splash Screen: False'
	fi
}

pi_services_interfaces() {
	### Check which services/interfaces are enabled
	echo '=== Raspbian-configurable Services & Interfaces ==='
	echo '- (raspi-config) Services and Interfaces  -'
	
	# P1 Camera
	if [[ $deb_version -le 10 ]]; then
		if [[ $(grep -oP '(?<=^start_x=).+' "$boot_config") -eq 1 ]]; then
			echo '(!) Camera enabled'
		fi
	else
		if [[ $(grep -oP '(?<=^camera_auto_detect=).+' "$boot_config") -eq 1 ]]; then
			echo '(!) Camera enabled'
      		else
			echo 'Camera disabled'
	      	fi
	fi
	
	# P2 SSH
	if [[ $(pstree -p | egrep --extended-regexp '.*sshd.*\(.+\)') ]]; then
		echo 'SSH enabled'
	else
		echo 'SSH disabled'
	fi
	
	# P3 VNC
	if [[ $(systemctl status vncserver-x11-serviced.service  2>/dev/null | grep -q -w active) ]]; then
		echo '(!) (Real)VNC: remote graphical GUI enabled'
	else
		echo '(Real)VNC disabled'
	fi
	
	# P4 SPI
	if [[ $(grep -q -E '^(device_tree_param|dtparam)=([^,]*,)*spi(=(on|true|yes|1))?(,.*)?$' $boot_config) ]]; then
		echo '(!) SPI: kernel module automatic loading enabled'
	else
		echo 'SPI disabled'
	fi
	
	# P5 I2C
	if [[ $(grep -q -E '^(device_tree_param|dtparam)=([^,]*,)*i2c(_arm)?(=(on|true|yes|1))?(,.*)?$' $boot_config) ]]; then
		echo '(!) I2C: kernel module automatic loading enabled'
	else
		echo 'I2C disabled'
	fi
	
	# P6 Onewire
	if [[ $(grep -q -E '^dtoverlay=w1-gpio' "$boot_config") ]]; then
		echo '(!) One-wire interface enabled'
	else
		echo 'One-wire disabled'
	fi
	
	# P7 Serial
	if [[ $(grep -q -E "console=(serial0|ttyAMA0|ttyS0)" $cmdline_location) ]]; then
		echo '(!) Serial: enabling Shell messages over serial port'
	else
		echo 'Serial disabled'
	fi

	# P8 Remote GPIO
	if [[ -f '/etc/systemd/system/pigpiod.service.d/public.conf' ]]; then
		echo '(!) GPIO: Remote server access enabled'
	else
		echo 'GPIO Remote server access disabled'
	fi
}


