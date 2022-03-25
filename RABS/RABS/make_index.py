#!/usr/bin/python3

import json
import os
from jinja2 import Environment, FileSystemLoader
import re

env = Environment(loader=FileSystemLoader('Reports/_templates'), trim_blocks=True, lstrip_blocks=True)
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

## Templating for index.html
# 1. Build dct of metadata
persistent_vars = {
	'total_wordlists': 0
}
lookup_dct={}


for data_dump in sorted(os.listdir('Reports/dumps')):
	chapter_dct = {
		'summary': {
		'passed': 0,
		'failed': 0,
		'unexecuted': 0,
		'manual': 0
		}
	}
	
	json_file = open('Reports/dumps/' + data_dump)
	dumped_dct = json.load(json_file)
	json_file.close()
	
	persistent_vars['total_wordlists'] += len(dumped_dct)
	for wordlist in dumped_dct:
		temp_dct = {
			'passed': 0,
			'failed': 0,
			'unexecuted': 0,
			'manual': 0
		}
		for module in dumped_dct[wordlist]:
			target = dumped_dct[wordlist][module]
			if 'true_manual' in target and target['true_manual']:
				temp_dct['manual'] += 1
			elif type(target['failed']) == dict and len(target['failed']) > 0:
				temp_dct['failed'] += 1
			elif type(target['failed']) == type(None) and target['ref_module']:
				temp_dct['unexecuted'] += 1
			else:
				temp_dct['passed'] += 1
		
		chapter_dct[wordlist] = temp_dct
		for statistic in temp_dct:
			chapter_dct['summary'][statistic] += temp_dct[statistic]
	
	persistent_vars[data_dump[0]] = chapter_dct


regex_pattern='^([0-9]+\.)+[0-9]+\.txt$'
for wordlist in sorted(os.listdir('modules')):
	if re.compile(regex_pattern).match(wordlist):
		with open('modules/' + wordlist) as temp:
			lookup_dct[os.path.splitext(wordlist)[0]] = temp.readlines()[0].lstrip('#').strip()


# 1a. Dump and save
with open('index.txt', 'w') as json_file:
	json.dump(lookup_dct, json_file, indent=4)

# 2. Return template
index_template = env.get_template('index.html')
output_from_index_template = index_template.render(dct=persistent_vars, lookup=lookup, lookup_dct=lookup_dct, locale=name_lookup)
with open('Reports/_Index.html', "w") as fh:
	fh.write(output_from_index_template)
