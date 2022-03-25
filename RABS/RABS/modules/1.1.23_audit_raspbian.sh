#!/bin/bash
for user in $(grep -P ":"$(grep -E '^/' '/etc/shells' | tr '\n' '|' | sed 's/.$//') '/etc/passwd'); do
	if [[ ! -f "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf" ]]; then
		echo "$(echo $user | cut -d ':' -f 1) : No pcmanfm.conf"
	elif [[ ! $(grep 'mount_on_startup=0' "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf") ]]; then
		echo "$(echo $user | cut -d ':' -f 1) : mount_on_startup enabled"
	elif [[ ! $(grep 'mount_removable=0' "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf") ]]; then
		echo "$(echo $user | cut -d ':' -f 1) : mount_removable enabled"
	elif [[ ! $(grep 'autorun=0' "$(echo $user | cut -d ':' -f 6)/.config/pcmanfm/LXDE-pi/pcmanfm.conf") ]]; then
		echo "$(echo $user | cut -d ':' -f 1) : autorun enabled"
	fi
done