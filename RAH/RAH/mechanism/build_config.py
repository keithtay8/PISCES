#!/usr/bin/python

import json
import os

os.chdir(os.path.dirname(os.path.realpath(__file__)))

dct = {}
modules_lst=os.listdir('../modules')
modules_lst.sort()
for filename in modules_lst:
	if len(filename) > 4 and filename[-3:] == '.sh':
		with open('../modules/' + filename) as file:
			for line in file.readlines():
				line = line.strip()
				if line and line[0] == '#':
					line = line[1:].lstrip()
					if ';;;' in line:
						split_lst = line.split(';;;')
						split_lst = split_lst[0].split(' ', 1) + split_lst[1:]
						dct[split_lst[0]] = split_lst[1:] + [filename, False]
if dct:
	if os.path.exists('./config.json'):
		target = open('./config.json')
		existing_dct = json.load(target)
		target.close()
		for key in dct:
			if key not in existing_dct:
				existing_dct.update({key: dct[key]})
			elif dct[key][:-1] != existing_dct[key][:-1]:
				existing_dct[key] = dct[key][:-1] + [existing_dct[key][-1]]
		dct = existing_dct
	target = open('./config.json', 'w')
	json.dump(dct, target, indent=4)
	target.close()
else:
	print('No acceptable modules found')