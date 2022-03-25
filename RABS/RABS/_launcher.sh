#!/bin/bash

### Initialization ###
export cis_dir="$(realpath $(dirname $0))"
oldIFS=$IFS
declare -A results_dct
python=$(if [[ `python -V 2>&1` == "Python 2.*" ]]; then echo 'python'; else echo 'python3'; fi)
bash_locale=$(which bash)
og_user="$(logname)"
if [[ ! -d "$cis_dir/Reports/dumps" ]]; then
	mkdir "$cis_dir/Reports/dumps"
fi
######################

### HELP ###
Help() {
	echo "PISCES RABS: A fully automated scanner designed to read certain wordlists, execute their contents and check the results. Existing worldlists based on CIS Benchmark for Ubuntu 20.04."
	echo "Syntax: _launcher.sh [-h|v]" && echo ""
	echo "h      Displays this help text"
	echo "v      Returns verbose output into the CLI"
}
############

### Arguments ###
while getopts ":hv" option; do
	case $option in
		h) # Help
			Help
			exit
			;;
		v) # Verbose
			verbose=1
			;;
		\?) # Catch errors
			echo '[ALERT] Invalid argument detected.'
			Help
			exit
			;;
	esac
done
#shift $((OPTIND -1))
#################

### Program ###
cd $cis_dir
chmod +x ./*.py
chmod +x ./modules/*.sh

regex_pattern='^([0-9]+\.)+[0-9]+\.txt$'
modules_lst=($(ls "$cis_dir/modules" | egrep $regex_pattern ))
declare -a modules_dct

# Stores the results as {key1: 'a b c', key2: 'd e f', etc}
for result in ${modules_lst[@]}; do
	key_from_split=$(cut -d '.' -f1 <<< $result)
	if [[ ${modules_dct[$key_from_split]}+abc ]]; then
		modules_dct[$key_from_split]+=" $result"
	else
		modules_dct[$key_from_split]=$result
	fi
done


for key in ${!modules_dct[@]}; do
	echo "Chapter $key"
	#IFS=$oldIFS
	
	## Make a string of '/path/file /path/file2 /path/file3'
	modules_lst=(${modules_dct[$key]}) mod_string=''
	for module in ${modules_lst[@]}; do
		mod_string+=" $cis_dir/modules/$module"
	done
	mod_string=$(echo $mod_string | xargs)
	#echo $mod_string
	
	## Pass the above string into python
	IFS=$'\n'; contents=(`$python $cis_dir/scanner.py $bash_locale $mod_string`)
	if [[ $verbose ]]; then
		for line in ${contents[@]}; do
			if [[ $line = *'Passed (modules)'* ]] || [[ $line = *'Failed (modules)'* ]] || [[ $line = *'Unexecuted (modules)'* ]]; then
				echo '' && echo '~~~~' 
			fi
			echo $line
		done
		echo '~~~~~' && echo && echo '========'
	fi
	IFS=$oldIFS
done

`$python $cis_dir/make_index.py`

# Dumps stuff
report_folder="$cis_dir/Reports/$(date '+%Y-%m-%d_%H%M-%S')"; mkdir "$report_folder"
find "$cis_dir/Reports" -maxdepth 1 -name "*.html" -exec mv '{}' "$report_folder" \;
mv "$cis_dir/Reports/dumps" "$report_folder"
chown -R "$og_user:$og_user" "$report_folder"