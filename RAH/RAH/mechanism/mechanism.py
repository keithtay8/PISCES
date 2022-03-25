#!/usr/bin/python

import os
import subprocess
import sys
import json
from time import sleep

### Define the Contextual Keywords and other settings
ending = '<<BREAKPOINT>>'
wr_prot = '<<WR_P>>'
audit = '<<AUDIT>>'

modules_that_need_background = ['1.3.1.sh']
#background_poll={'frequency': 5, 'max': 6}

### Set the Working Directory
os.chdir(os.path.dirname(os.path.realpath(__file__)))

### Determine which modules need to be executed
json_file = open("./config.json")
json_dct = json.load(json_file)
json_file.close()

if len(sys.argv) == 2:
	script = sys.argv[1]
	args_lst = ''
	for module in json_dct:
		if script == json_dct[module][2]:
			args_lst += str(int(json_dct[module][-1]))
			if script in modules_that_need_background:
				bg_module = module
	
	### Run the files
	the_file = '../modules/%s' % script
	#args_lst = dct[script]

	with open(the_file) as target_files:
		modules_dct = {}
		for line in target_files.readlines():
			line = line.strip()
			if line and line[0] == '#':
				if ';;;' in line:
					split_lst = line.split(';;;')
					modules_dct[split_lst[0][1:].lstrip()] = split_lst[1]
			else:
				break

		### Toggling modules by supply arguments
		if len(args_lst) < len(modules_dct):
			print('Skipped: Too little arguments, expected (%s) but supplied (%s) for \'%s\'' % (len(modules_dct), len(args_lst), script))
			exit()
		elif '1' not in args_lst:
			exit()
		
		### Execution Engine
		## Check if module should be backgrounded and do required actions
		for module in modules_that_need_background:
			if module in the_file:
				process=subprocess.Popen('%s %s'%(the_file, args_lst), shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
				#for count in range(background_poll['max']):
				#	if process.poll():
				#		break
				#	sleep(background_poll['frequency'])
				#if process.poll():
				#	break
				#else:
				print('%s%s : %s\e[0m %s~~~%d'%('\e[1;33m', ' '.join([bg_module, json_dct[bg_module][0]]), 'Ran in Background', bg_module, process.pid))
				exit()
		process=subprocess.Popen('%s %s'%(the_file, args_lst), shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		try:
			result=process.communicate()[0]
			result=result.decode('utf-8').split('\n')
			result=list(filter(None, result))
		except subprocess.TimeoutExpired:
			process.kill()
			result=['Terminated, took longer than %d seconds'%(custom_timeout)]
			print('DIED from timeout')
			exit()
		
		### Dividing if multiple modules in one
		if len(modules_dct) > 1:
			results_splicing = {}
			for count in range(len(args_lst)):
				if args_lst[count] == '1':
					module = list(modules_dct)[count]
					if wr_prot in result[:(result.index(ending))]:
						status = 'Write-Protection Triggered'
					elif audit in result[:(result.index(ending))]:
						status = 'Audit passed'
					else:
						if modules_dct[module] in result[:(result.index(ending))]:
							status = 'Success'
						else:
							status = 'Fail'
					results_splicing[module] = [status, result[:(result.index(ending))]]
				result = result[(result.index(ending) + 1):]
			result=results_splicing
		else:
			module = list(modules_dct)[0]
			if wr_prot in result:
				status = 'Write-Protection Triggered'
			elif audit in result:
				status = 'Audit passed'
			else:
				if modules_dct[module] in result:
					status = 'Success'
				else:
					status = 'Fail'
			result = {module: [status, result]}
		
		### Assess results
		#[print('%s : %s'%(module, result[module][0])) for module in result]
		for module in result:
			if result[module][0] in ['Write-Protection Triggered', 'Fail']:
				code='\e[41m'
			else:
				code='\e[0m'
			print('%s%s : %s\e[0m'%(code, module, result[module][0]))
		
		### Dump in case
		target = open('../reports/%s.json' % script, 'w')
		json.dump(result, target, indent=4)
		target.close()

