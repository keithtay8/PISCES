#!/bin/bash
# Additional hardening measures
# P1.1 Default users are locked;;;P1.1: success
# P1.2 Ensure all login users have no volume automounting in Desktop mode;;;P1.2: success
# P1.3 Ensure Pi is booting into CLI instead of desktop;;;P1.3: success
# P1.4 Limit open interfaces to SSH only;;;P1.4: success
# P1.5 Ensure Apparmor is enabled in bootloader configuration;;;P1.5: success
# P1.6 Disable display outputs;;;P1.6: success
# P1.7 Ensure boot partition is read-only;;;P1.7: success

audit='<<AUDIT>>'
breakpoint='<<BREAKPOINT>>'
wr_p='<<WR_P>>'

if [[ ${BASH_ARGV:0:1} = 1 ]]; then
	# P1.1: Get all default users' hashes stored in the 'users' variable and lock them
	# Adds a fallback user in case no other login method is present
	counter=1
	users=('root' 'pi')
	if [[ ! $(cat /etc/shadow | grep -P "($(echo ${users[@]} | tr ' ' '|')):" | grep -P ':\$[a-zA-Z0-9/\$\.]+:') ]]; then
		echo "$audit"
	else
		emergency_user='ahs_alt' emergency_password='alt_user@AHS'
		for hash in $(cat /etc/shadow | grep -P "($(echo ${users[@]} | tr ' ' '|')):" | grep -P ':\$[a-zA-Z0-9/\$\.]+:'); do
			bash -c "passwd -dl $(echo $hash | cut -d ':' -f1) 1>/dev/null" && echo "[P1.$counter] $(echo $hash | cut -d ':' -f1)'s account has been locked"
		done
		(cat /etc/shadow | grep -P ':\$[a-zA-Z0-9/\$\.]+:' | grep -vPq "($(echo ${users[@]} | tr ' ' '|')):") || \
			(useradd $emergency_user; \
			echo -e "$emergency_password\n$emergency_password" | passwd $emergency_user &>/dev/null; \
			sudo usermod -aG sudo "$emergency_user"; \
			echo -e "[P1.$counter] '$emergency_user' with password '$emergency_password' has been added due to no other password logins\nPlease delete this user when unrequired.")
		echo "P1.$counter: success"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:1:1} = 1 ]]; then
	# P1.2: Searches for users with valid shells. If the user does not have the pcmanfm.conf, the file is forcefully created with the contents
	# If pcmanfm.conf exists, it will only modify the necessary strings.
	counter=2
	for user in $(grep -P ":"$(grep -E '^/' '/etc/shells' | tr '\n' '|' | sed 's/.$//') '/etc/passwd'); do
		if [[ ! -f "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf" ]]; then
			mkdir -p "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/"
			echo -e '[volume]\nmount_on_startup=0\nmount_removable=0\nautorun=0\n' > "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf"
			chmod g-wx,o-rwx "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf"
		else
			rules=('mount_on_startup' 'mount_removable' 'autorun')
			for rule in ${rules[@]}; do sed -i "/^$rule=[1-9]/c\\$rule=0" "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf"; done
		fi
	done
	echo "P1.$counter: success"
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:2:1} = 1 ]]; then
	# P1.3: Boot to CLI instead of GUI by default
	counter=3
	systemctl set-default multi-user.target
        ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
        rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
	echo "P1.$counter: success"
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:3:1} = 1 ]]; then
	# P1.4: Disable all interfaces (except SSH). Uses code from 'raspi-config'
	counter=4
	CONFIG='/boot/config.txt'
	CMDLINE=/boot/cmdline.txt
	BLACKLIST=/etc/modprobe.d/raspi-blacklist.conf
	SETTING=off
	STATUS=disabled
	
	deb_ver () {
		ver=`cat /etc/debian_version | cut -d . -f 1`
		echo $ver
	}
	
	## (1) Camera
	if [ $(deb_ver) -le 10 ] ; then
		set_config_var start_x 0 $CONFIG
		sed $CONFIG -i -e "s/^start_file/#start_file/"
	else
		sed $CONFIG -i -e "s/^camera_auto_detect=1/camera_auto_detect=0/"
	fi
	echo "[P1.$counter] (1) The Camera interface is disabled"
	
	## (2) VNC
	if [ "echo $(dpkg -l "realvnc-vnc-server" 2> /dev/null | tail -n 1 | cut -d ' ' -f 1)" != "ii" ]; then
		systemctl disable vncserver-x11-serviced.service
		systemctl stop vncserver-x11-serviced.service
	fi
	echo "[P1.$counter] (2) The VNC interface is disabled"
	
	## (3) SPI
	sed -i 's/^dtparam=spi=on/dtparam=spi=off/' $CONFIG
	if ! [ -e $BLACKLIST ]; then
		touch $BLACKLIST
	fi
	sed $BLACKLIST -i -e "s/^\(blacklist[[:space:]]*spi[-_]bcm2708\)/#\1/"
	dtparam spi=off
	echo "[P1.$counter] (3) The SPI interface is disabled"
	
	## (4) I2C
	sed -i 's/^dtparam=i2c_arm=on/dtparam=i2c_arm=off/' $CONFIG
	if ! [ -e $BLACKLIST ]; then
		touch $BLACKLIST
	fi
	sed $BLACKLIST -i -e "s/^\(blacklist[[:space:]]*i2c[-_]bcm2708\)/#\1/"
	sed /etc/modules -i -e "s/^#[[:space:]]*\(i2c[-_]dev\)/\1/"
	if ! grep -q "^i2c[-_]dev" /etc/modules; then
		printf "i2c-dev\n" >> /etc/modules
	fi
	dtparam i2c_arm=off
	modprobe i2c-dev
	echo -e "[P1.$counter] (4) The ARM I2C interface is $STATUS"
	
	## (5) Serial Port
	sed -i $CMDLINE -e "s/console=ttyAMA0,[0-9]\+ //"
	sed -i $CMDLINE -e "s/console=serial0,[0-9]\+ //"
	SSTATUS=disabled
	sed -i 's/^enable_uart=1/enable_uart=0/' $CONFIG
	HSTATUS=disabled
	echo -e "[P1.$counter] (5) The serial login shell is $SSTATUS, the serial interface is $HSTATUS"
	
	## (6) 1-Wire
	sed $CONFIG -i -e "s/^dtoverlay=w1-gpio/#dtoverlay=w1-gpio/"
	echo "[P1.$counter] (6) The one-wire interface is $STATUS"
	
	## (7) Remote GPIO
	rm -f /etc/systemd/system/pigpiod.service.d/public.conf
	systemctl daemon-reload
	systemctl -q is-enabled pigpiod && systemctl restart pigpiod
	echo "[P1.$counter] (7) The Remote GPIO interface is disabled"
	
	echo "P1.$counter: success"
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:4:1} = 1 ]]; then
	# P1.5: Add apparmor to bootloader configuration (assuming Apparmor is installed)
	counter=5
	if [[ $(grep -P '(?=^.+apparmor=1)(?=^.+security=apparmor)' /boot/cmdline.txt) ]]; then
		echo "$audit"
	else
		if [[ ! $(grep 'apparmor=1' /boot/cmdline.txt) ]]; then
			echo "$(cat /boot/cmdline.txt) apparmor=1" > '/boot/cmdline.txt'
		fi
		if [[ ! $(grep 'security=apparmor' /boot/cmdline.txt) ]]; then
			echo "$(cat /boot/cmdline.txt) security=apparmor" > '/boot/cmdline.txt'
		fi
		echo "P1.$counter: success"
	fi
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:5:1} = 1 ]]; then
	# P1.6: Sets parameters to ensure that there will be no display outputs
	counter=6
	declare -A args_lst=(
		['hdmi_blanking']='1'
		['disable_splash']='1'
		['hdmi_ignore_hotplug']='1'
		['quiet']=''
		['logo.nologo']=''
		['vt.global_cursor_default']='0'
		['dtoverlay']='vc4-fkms-v3d'
	)
	
	[[ $(cat /proc/mounts | grep '/boot ' | grep -o 'ro,') ]] && flag=1 && echo -e "[P1.$counter] Boot is read-only, some changes do not take hold. Run this again after making Boot writeable"
	if [[ $flag ]]; then
		echo "$wr_p"
	else
		for rule in ${!args_lst[@]}; do
			if [[ $(grep -P "^$rule" '/boot/config.txt') ]]; then
				[[ ${args_lst[$rule]} ]] && sed -i "s/^$rule=.\+/$rule=${args_lst[$rule]}/" '/boot/config.txt'
			else
				if [[ ${args_lst[$rule]} ]]; then
					echo "$rule=${args_lst[$rule]}" >> "/boot/config.txt"
				else
					echo "$rule" >> "/boot/config.txt"
				fi
			fi
		done
		if [[ -f '/var/spool/cron/crontabs/root' ]]; then
			oldIFS=$IFS IFS=$'\n' crontab_rules=('@reboot vcgencmd display_power 0' '@reboot tvservice -o')
			for i in ${crontab_rules[@]}; do
				if [[ ! $(grep -P "^$i\$" '/var/spool/cron/crontabs/root') ]]; then
					(crontab -l 2>/dev/null; echo "$i") | crontab -
				fi
			done
			IFS=$oldIFS
		fi
	fi
	echo "P1.$counter: success"
fi
echo "$breakpoint"

if [[ ${BASH_ARGV:6:1} = 1 ]]; then
	# P1.7: Set boot partition to be read-only
	counter=7
	$(findmnt /boot | grep -q " ro,") &&\
		echo "$audit" ||\
		(sed -i /etc/fstab -e "s/\(.*\/boot.*\)defaults\(.*\)/\1defaults,ro\2/"; if ! mount -o remount,ro /boot 2>/dev/null ; then echo "Unable to remount boot partition as read-only"; fi; echo "P1.$counter: success")
fi
echo "$breakpoint"
