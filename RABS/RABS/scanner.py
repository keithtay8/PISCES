#!/usr/bin/python3

import os, subprocess, re
import sys
import json

## 0. Initialization
if sys.version.split()[0][0] == '2':
	raise ValueError('[ALERT] Python version must be at least 3')

if len(sys.argv) > 2:
	bash = sys.argv[1]
	path_lst=sys.argv[2].split()


universal_results={}


## THE LOOP STARTS HERE
for target in path_lst:
	
	## 1.Read through wordlists
	with open(target,'r') as file:
		all_results={}
		## current_module: determines if its under a [0.1.2 / title / manual]{toggle}, affects whether to scan for or not
		## current_test: determines if a module is to load up a command or not, saves the command
		## inactive: skip everything until the next module header is found
		## [UNUSED-INCOMPLETE] expect_as_or: determines if an audit command is to be treated as an alternative to a previous one
		current_module, current_test=None, {} 
		inactive=False
		#expect_as_or=False
		for line in file:
			line=line.rstrip()
			if line:
				#print('[DEBUG-0] current_module>>>', current_module)
				#print('[DEBUG-0] line>>>', line)
				
				## Linked modules: <...>
				if ( line[0] == '<' ) and '>' in line:
					ref_module=line[1:line.index('>')]
					line=line[line.index('>')+1:]
					if ( '<' in line ) or ( '>' in line):
						continue
				else:
					ref_module=None
				
				## Comments: #
				if line.strip()[0] == '#':
					continue
				
				## Module header: [...]{...}
				elif ( line[0] == '[' ) and ( ']' in line ) and ( '{' in line ) and ( line[-1] == '}' ):
					
					if ( line[0] == '[' ) and ( line[-1] == '}'):
						line=line[1:-1]
						if ( '[' in line ) or ( '}' in line ):
							continue
						else:
							stored_indexes, violated, templine=[-1, -1], [False, False], line
							while stored_indexes[0] == -1 or stored_indexes[1] == -1:
								if ']' in templine:
									if stored_indexes[0] == -1:
										stored_indexes[0]=line.index(']')
										templine=templine[:stored_indexes[0]] + templine[stored_indexes[0]+1:]
									else:
										violated[0]=True
								elif '{' in line:
									if stored_indexes[1] == -1:
										stored_indexes[1]=line.index('{')
										templine=templine[:stored_indexes[1]] + templine[stored_indexes[1]+1:]
									else:
										violated[1]=True
								if violated[0] or violated[1]:
									break
							if violated[0] or violated[1]:
								continue
							else:
								line_status=line[ stored_indexes[1]+1: ]
								if line_status.lower() != 'active':
									inactive=True
									continue
								else:
									inactive=False
									if current_test:
										current_test=None
									
									line_options=line[: stored_indexes[0] ]
									line_options=line_options.split(' || ')
									
									for i in line_options:
										i=i.strip()
									
									all_results[line_options[0]]={'executed': False, 'options': line_options[1:], 'audit': {}, 'failed': {}, 'result': {}}
									if ref_module:
										### Dependent module
										all_results[line_options[0]].update({'ref_module': ref_module})
									if line_options[1][:3] == '(!)':
										### True manual
										all_results[line_options[0]].update({'true_manual': True})
										
									current_module=line_options[0]
				
				elif current_module:
					if inactive:
						continue
					
					## Indented lines, aka To-Audit-Against>>> \t
					if line[0] == "\t":
						## Ignore if not scanning with a selected audit rule
						if not current_test:
							continue
						else:
							## Regex Audit-case>>> \t~\t
							## Normal Audit-case>>> \t
							if line[1:] == '':
								continue
							all_results[current_module]['audit'][current_test].append(line[1:])
					
					## Unindented lines, aka Rules
					else:
						temp_dct=all_results[current_module]['audit']
						temp_dct[line]=[]
						all_results[current_module]['audit']=temp_dct
						current_test=line

	## 2.Begin processing against rules
	if all_results:
		for module in all_results:
			
			## Skip commands that have been 'ran'
			if all_results[module]['executed']:
				continue
			
			#print('[DEBUG-%s] Starting'%module)
			## Checking for ref_module flag, determines if execute module or not
			if 'ref_module' in all_results[module].keys():
				ref_module=all_results[module]['ref_module']
				pass_condition=False
				if ref_module in all_results.keys():
					if all_results[ref_module]:
						if all_results[ref_module]['executed'] and not all_results[ref_module]['failed']:
							pass_condition=True
				if not pass_condition:
					all_results[module]['executed']=True
					all_results[module]['failed']=None
					continue
			
			## Processing begins
			for test_case in all_results[module]['audit']:
				executable_cmd = test_case
				audit_case = all_results[module]['audit'][test_case]
				
				process=subprocess.Popen(executable_cmd, executable=bash, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
				custom_timeout=300
				try:
					result=process.communicate(timeout=custom_timeout)[0]
					result=result.decode('utf-8').split('\n')
					result=list(filter(None, result))
				except subprocess.TimeoutExpired:
					process.kill()
					result=['Terminated, took longer than %d seconds'%(custom_timeout)]

				if not all_results[module]['executed']:
					all_results[module]['executed']=True

				if result:
					if 'result' not in all_results[module].keys():
						all_results[module]['result']={list(all_results[module]['audit'].keys()).index(test_case): result}
					else:
						all_results[module]['result'][list(all_results[module]['audit'].keys()).index(test_case)] = result
				
				dct_of_rules={"standard":{}, "regex":{}}
				if len(audit_case):
					for count in range(len(audit_case)):
						if audit_case[count][:2] == '~\t':
							dct_of_rules["regex"][count]=audit_case[count][2:]
						else:
							dct_of_rules["standard"][count]=audit_case[count]
				else:
					dct_of_rules=None
				
				#print('[DEBUG-%s] dct_of_rules, audit_case>>>'%module, dct_of_rules, audit_case)
			
				## Checking if manual intervention needed
				if 'true_manual' in all_results[module].keys() and all_results[module]['true_manual']:
					continue
					
				### Rule handling
				if dct_of_rules:
					## If there are rules, this path executes
					## I.Standard handling: interpret as literal, this will directly record failures
					for std_cmd in dct_of_rules["standard"]:
						expected_output=dct_of_rules["standard"][std_cmd]
						
						## 2nd cond: For when both result and expected_output are [], only possible way to proc this
						
						if not (expected_output in result):
							index_of_cmd=list(all_results[module]['audit'].keys()).index(test_case)
							
							if not index_of_cmd in all_results[module]['failed'].keys():
								all_results[module]['failed'][index_of_cmd]=[std_cmd]
							else:
								all_results[module]['failed'][index_of_cmd].append(std_cmd)

					
					## II.Regex handling: interpret as regex, this dct keeps track of success than inverses to get failures
					if dct_of_rules["regex"]:
						if module == '3.5.1.4':
							print('[DEBUG-lol]:', dct_of_rules["regex"])
						
						# a.Looking for matching regex
						matched=[]
						while len(result):
							to_regex_against=result[0]
							for count in dct_of_rules["regex"]:
								
								if dct_of_rules["regex"][count][:2] == '(?':
									if re.compile(str(dct_of_rules["regex"][count])).match(to_regex_against):
										matched.append(count)
										break
								else:
									if re.compile(str('^'+dct_of_rules["regex"][count]+'$')).match(to_regex_against):
										matched.append(count)
										break
							result=result[1:]

						# b.Inversing results to get violators
						lst_holding_indices=[]
						for i in range(len(dct_of_rules["regex"])):
							if i not in matched:
								lst_holding_indices.append(i)
						violators=list(set(lst_holding_indices) - set(matched))
						
						# c.Writing back 'violators' to all_results
						if violators:
							index_of_cmd=list(all_results[module]['audit'].keys()).index(test_case)
							if not list(all_results[module]['audit'].keys()).index(test_case) in all_results[module]['failed'].keys():
								all_results[module]['failed'][index_of_cmd]=violators
							else:
								all_results[module]['failed'][index_of_cmd]=all_results[module]['failed'][index_of_cmd]+violators
				
					
				else:
					## If there are no rules (aka expecting no output), this path executes
					if result:
						index_of_cmd=list(all_results[module]['audit'].keys()).index(test_case)
						if not all_results[module]['failed']:
							all_results[module]['failed']={index_of_cmd: None}
						else:
							all_results[module]['failed'][index_of_cmd]=None
	
	
	## DEBUG: Return 'all_results' object after processing against rules
	#my_obj=json.dumps(all_results, indent=4)
	#print('[DEBUG-Processed] all_results>>>', my_obj)
	#exit()

	## 3.Handle the results of all checking before output formatting
	final_outputs={}
	for module in all_results:
		final_outputs[module]=[]
		key_lst=list(all_results[module]['audit'].keys())
		
		### {} IS PASS
		### If true_manual is 'True' then IGNORE
		### {0: ..., 1: ..., etc} IS FAIl
		### NONE IS INSTANT FAIL
		
		if 'true_manual' in all_results[module] and all_results[module]['true_manual']:
			final_outputs[module] = ["true_manual"]
			continue
		
		elif not all_results[module]['failed'] == {}:
			
			## Counts number of audit commands for the <int>/<total>
			final_outputs[module].append(str(len(all_results[module]['audit'])))

			## Fail INSTANTLY due to linked module failing
			if all_results[module]['failed'] == None:
				final_outputs[module] = [all_results[module]['ref_module']]
				continue
			
			for violation in all_results[module]['failed']:
				## Fail due to output returned
				if not all_results[module]['failed'][violation]:
					## Handle fail due to output being returned when none expected
					final_outputs[module].append(
						[
							key_lst[int(violation)],
							"No output expected, but output received"
						]
					)
				
				## Fail due to violation
				else:
					## Handle everything else
					final_outputs[module].append(
						[
							key_lst[int(violation)],
							"%d unmatched output(s)"%len(all_results[module]['failed'][violation])
						]
					)
		## PASS CASE
		if all_results[module]['failed'] == {}:
			final_outputs[module] = ["pass"]
			continue


	## 4.Format output as neat columns
	col_width=max(len(target_data[0]) for key in final_outputs for target_data in final_outputs[key]) + 2
	pass_dct, fail_dct, unexec_dct, manual_dct = {}, {}, {}, {}
	#fail_dct={}
	#unexec_dct={}
	for module in final_outputs:
		## Pass or Manual audit cases
		# pass_dct={"module": ["module_name", "automated/manual"], ...}
		if final_outputs[module] == ["pass"]:
			pass_dct[module]=all_results[module]['options']
		elif final_outputs[module] == ["true_manual"]:
			manual_dct[module]=all_results[module]['options']
		else:
			for case in final_outputs[module]:
				if type(case) == str and not case.isnumeric():
					## Unexecuted cases
					# unexec_dct={"ref_module": ["module", ...], ...}
					
					if not case in unexec_dct.keys():
						unexec_dct[case]=[module]
					else:
						unexec_dct[case].append(module)
				
				else:
					## Failed cases
					# fail_dct={"module": ["module_desc", "Failed checks: int", "each_error_msg", ...], ...}
					
					if not module in fail_dct.keys():
						fail_dct[module]=['%s - %s, %s'%(module, all_results[module]['options'][0], all_results[module]['options'][1])]
						fail_dct[module].append('(%d/%s) Failed checks:'%(len(final_outputs[module])-1, case))
					if type(case) != str:
						fail_dct[module].append(str('|---' + (''.join(str(point).ljust(col_width) for point in case)).strip()))

	## 5.Return output
	print('=== Results of processing: ===')
	print('Section: %s'%os.path.basename(target)[:-4])
	print('Loaded modules: %d\n'%len(all_results.keys()))

	print('Passed (modules):', len(pass_dct))
	for pass_case in pass_dct:
		print('%s - %s, %s'%(pass_case, pass_dct[pass_case][0], pass_dct[pass_case][1]))
	print()

	print('Failed (modules):', len(fail_dct))
	for fail_case in fail_dct:
		for msg in fail_dct[fail_case]:
			print(msg)
		print('~~~~~~')
	print()

	print('Manual discretion needed (modules):', len(manual_dct))
	for manual_case in manual_dct:
		for msg in manual_dct[manual_case]:
			print(msg)
		print('~~~~~~')
	print()

	unexec_len=0
	unexec_results=[]
	for unexec in unexec_dct:
		unexec_results.append(unexec)
		unexec_len+=len(unexec_dct[unexec])
		for i in unexec_dct[unexec]:
			unexec_results.append('|---%s - %s, %s'%(i, all_results[i]['options'][0], all_results[i]['options'][1]))
	print('Unexecuted (modules) since linked module failed the audit:', unexec_len)
	for line in unexec_results:
		print(line)

	## 6. Save into universal_results
	universal_results[os.path.split(target)[-1]]=all_results


## 7. HTML REPORT SAVING
num = int(str(os.path.splitext(list(universal_results.keys())[0])[0])[0])
try:
	config_file = open('./config.json')
	config_obj = json.load(config_file)
	config_file.close()
except:
	config_obj={'1': 'Initial Setup', '2': 'Services', '3': 'Network Configuration', '4': 'Logging And Auditing', '5': 'Access, Authentication And Authorization', '6': 'System Maintenance'}
	config_file = open('./config.json', 'w')
	json.dump(config_obj, config_file, indent=4)
	config_file.close()

lookup, name_lookup = [], []
for title_int in config_obj:
	if title_int.isnumeric():
		title_int = int(title_int)
		if len(name_lookup) < (title_int + 1):
			for count in range(title_int - len(name_lookup) + 1):
				name_lookup.append(str(len(name_lookup) + count))
				lookup.append(str(len(lookup) + count))
		lookup[title_int] = config_obj[str(title_int)]
		name_lookup[title_int] = ''.join([character if character.isalpha() else '' for character in config_obj[str(title_int)]])

lookup_dct=json.load(open('index.txt')) if 'index.txt' in os.listdir() else {}

# For some reason, saving the dict to a file then reading it causes less issues THAN parsing it directly
json_file = open('Reports/dumps/{}_{}.txt'.format(str(num), name_lookup[num]), 'w')
json.dump(universal_results, json_file, indent=4)
json_file.close()
json_file = open('Reports/dumps/{}_{}.txt'.format(str(num), name_lookup[num]))
universal_results = json.load(json_file)
json_file.close()

def save_html():
	from jinja2 import Environment, FileSystemLoader
	
	## Templating for <page>.html
	env = Environment(loader=FileSystemLoader('Reports/_templates'), trim_blocks=True, lstrip_blocks=True)
	template = env.get_template('page.html')
	output_from_parsed_template = template.render(dct=universal_results, lookup=lookup, lookup_dct=lookup_dct)
	html_name = '{}_{}.html'.format(str(num), name_lookup[num])

	# to save the results
	with open('Reports/'+html_name, "w") as fh:
		fh.write(output_from_parsed_template)

save_html()
