#!/usr/bin/python

import sys
import os
import subprocess
import json
import re

### Set the Working Directory
os.chdir(os.path.dirname(os.path.realpath(__file__)))

### Prepare data set
json_file = open("./config.json")
json_dct = json.load(json_file)
json_file.close()

if len(sys.argv) == 1:

	### Prepare window size for whiptail
	wt_height = 18
	process = subprocess.Popen("bash -c 'WT_WIDTH=$(tput cols); if [ -z \"$WT_WIDTH\" ] || [ \"$WT_WIDTH\" -lt 60 ]; then WT_WIDTH=80; fi; if [ \"$WT_WIDTH\" -gt 178 ]; then WT_WIDTH=120; fi; echo $WT_WIDTH'", shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	wt_width = int(process.communicate()[0].decode('utf-8').split('\n')[0])
	wt_menu_height = wt_height-7

	### Prompt via CLI
	modules_string = ''
	for key in json_dct:
		temp = json_dct[key][0]
		if "'" in temp:
			for match in re.finditer("'", temp):
				temp = temp[:match.start()] + '"' + temp[match.start()+1:]
		modules_string+='\'%s\' \'%s\' \'%s\' '%(key, temp, 'ON' if json_dct[key][-1] == True else 'OFF')
	#os.system("choices=$(whiptail --separate-output --checklist 'Choose the options' %d %d %d %s 3>&1 1>&2 2>&3); echo $choices > ./cli_output.txt"%(wt_height, wt_width, wt_menu_height, modules_string))
	print("choices=$(whiptail --separate-output --checklist 'Select from the options: <[SPACE]: Select, [ENTER]: Submit, [ESC]: Abort>' %d %d %d %s 3>&1 1>&2 2>&3); echo $choices"%(wt_height, wt_width, wt_menu_height, modules_string))

else:
	
	### Write back to json
	for module in json_dct:
		if module in sys.argv[1:]:
			json_dct[module][-1] = True
		else:
			json_dct[module][-1] = False
	target = open('./config.json', 'w')
	json.dump(json_dct, target, indent=4)
	target.close()




