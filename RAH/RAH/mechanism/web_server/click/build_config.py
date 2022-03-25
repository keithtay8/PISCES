#!/usr/bin/python

import os

dct={}
temp=os.listdir('./modules')
temp.sort()
for filename in temp:
	try:
		if filename[-3:] == '.sh':
			with open('./modules/' + filename) as file:
				for line in file.readlines():
					line = line.strip()
					if line and line[0] == '#':
						if ';;;' in line:
							split_lst = line.split(';;;')
							split_lst = split_lst[0][2:].split(' ', 1) + split_lst[1:]
							dct[split_lst[0]]=[split_lst[1], split_lst[2], filename, False]
					else:
						break
	except:
		continue

if not dct:
	print('No valid rules detected')
	exit()

### Dump
import json
target = open('config.json', 'w')
json.dump(dct, target, indent=4)
target.close()
