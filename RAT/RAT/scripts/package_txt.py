#!/usr/bin/python3

import re, os


## 1.Compile following regex patterns for later use
# patterns=[PACKAGE_NAME, FILEPATH, API_ENCLOSURE, API_OPERATION]
patterns=["^\[.+\]$", "^(\/.+)+$", "^\t<;;<.+>;;>$", "\(;;\(.+\);;\)"]
for count in range(len(patterns)):
	patterns[count]=re.compile(patterns[count])


## 2.Store all lines of packages.txt
pkg_txt=[]
for line in open(os.environ["PKG_SRC"],'r'):
#for line in open('/home/pi/PChecker/lists/packages.txt','r'):
	pkg_txt.append(line)


## 3.Dictionary to hold all rules
pkg_dct={}
latest={'pkg':"", 'path':""}
can_accept_operation={}

## 4.Compiling all rules
for line in pkg_txt:
	line, pattern_match = line.rstrip(), -1

	## Check to make sure line isn't empty or just spaces
	if line.isspace() or line == '' or line[0] == '#':
		continue
	
	## See which pattern the line is matched to
	for pattern in patterns:
		if pattern.match(line):
			pattern_match = patterns.index(pattern)
	
	## PACKAGE NAME: read for [pkg_name] to then add as DCT[pkg_name]={}
	if pattern_match == 0:
		#print('PACKAGE_NAME', line)
		pkg_dct[ line[1:-1] ]={}
		latest['pkg']=line[1:-1]
		continue
	
	## FILEPATH: read for file_path to then add as DCT[pkg_name][file_path]={}
	elif pattern_match == 1:
		#print('FILEPATH', line)
		pkg_dct[ latest['pkg'] ][ line ]={'enclosure': [], 'operation': []}
		latest['path']=line
		can_accept_operation[line] = 0
		continue
	
	if latest['pkg'] != "" and latest['path'] != "":
		
		## API_ENCLSOURE: read for custom start then add as DCT[pkg_name][file_path]={'head':custom_start}
		if pattern_match == 2:
			#print('API_ENCLOSURE', line)
			pkg_dct[ latest['pkg'] ][ latest['path'] ][ 'enclosure' ].append(line[5: -4])
			can_accept_operation[ latest['path'] ] += 1
		
		else:
			#print('proc>>> ', line)
			if can_accept_operation[ latest['path'] ] == 0 or can_accept_operation[ latest['path'] ] % 2 != 0:
				pkg_dct[ latest['pkg'] ][ latest['path'] ][ 'operation' ].append( '^'+line[1:]+'$' )

#print('[DEBUG] pkg_dct>>>', pkg_dct)
results={}

## 5.Parsing all rules
for pkg_name in pkg_dct.keys():
	pkg_file_lst=pkg_dct[ pkg_name ].keys()
	results[pkg_name]=[]
	
	for pkg_config_path in pkg_file_lst:
		#print('[DEBUG] ', pkg_config_path)
		
		## Prepare arguments
		arg_enclosure=pkg_dct[ pkg_name ][ pkg_config_path ][ 'enclosure' ]
		arg_operations=[]
		for count in range(len(pkg_dct[ pkg_name ][ pkg_config_path ][ 'operation' ])):
			arg_operations.append( re.compile(pkg_dct[ pkg_name ][ pkg_config_path ][ 'operation' ][count]) )

		if not arg_operations:
			## Check operations not empty
			results[pkg_name].append(['|---', pkg_config_path, 'NIL', ''])
			continue
		
		# Prepare package's config file first
		target_file=[]
		try:
			for line in open(pkg_config_path, 'r'):
				target_file.append(line)
		except FileNotFoundError:
			results[pkg_name].append(['|---', pkg_config_path, 'MISSING', ''])
			continue
		
		# Processing begins
		enclosure = 0
		for line in target_file:
			if not arg_operations:
				## Quit searching file once operations is empty
				break
			
			line = line.rstrip()
			
			## Check if line matches the enclosure argument
			if not enclosure:
				if not arg_enclosure:
					## Avoid deadlock if not a single enclosure was given, so it will iterate through whole file
					enclosure=1
				else:
					if re.compile(arg_enclosure[0]).match(line):
						#print('STARTING ENCLOSURE FOUND>>> ',line)
						enclosure = 1
						arg_enclosure = arg_enclosure[1:]
						continue
			
			else:
				if arg_enclosure:
					if re.compile(arg_enclosure[0]).match(line):
						#print(' CLOSING ENCLOSURE FOUND>>> ',line)
						enclosure = 0
						arg_enclosure = arg_enclosure[1:]
						continue
			
				## Pass line through all arguments
				for regex_line in arg_operations:
					if regex_line.match(line):
						arg_operations.remove(regex_line)
						#print('[PROC]', regex_line)
						#print('[OPERATIONS]>>> ', arg_operations)
		
		#results[pkg_config_path]=arg_operations
		if arg_operations:
			results[pkg_name].append(['|---', pkg_config_path, 'UNCOMPLIANT', str(len(arg_operations))+' unmatched lines'])
		else:
			results[pkg_name].append(['|---', pkg_config_path, 'COMPLIANT', ''])

#print(results)
if results:
	first_lst, final_lst, formatted_dct=[], [], {}
	for key in results:
		for row in results[key]:
			first_lst.append(row)
			
			# CONDITIONS: 'COMPLIANT', 'UNCOMPLIANT', 'MISSING', 'NIL')
			if row[2] in [ 'UNCOMPLIANT', 'MISSING']:
				try:
					formatted_dct[key][1].append( first_lst.index(row) )
				except KeyError:
					formatted_dct[key] = [ [], [ first_lst.index(row) ] ]
			else:
				try:
					formatted_dct[key][0].append( first_lst.index(row) )
				except KeyError:
					formatted_dct[key] = [ [ first_lst.index(row) ], [] ]
	
	#print(first_lst, formatted_dct)
	rows = first_lst
	widths = [max(map(len, col)) for col in zip(*rows)]
	for row in first_lst:
		final_lst.append("  ".join((val.ljust(width) for val, width in zip(row, widths))))
	
	for key in formatted_dct:
		print( key, '\n| ', str( len(formatted_dct[key][0]) )+'/'+str( len(formatted_dct[key][0]) + len(formatted_dct[key][1]) )+' files are compliant')
		for compliant_number in formatted_dct[key][0]:
			print(final_lst[compliant_number])
		for uncompliant_number in formatted_dct[key][1]:
			print(final_lst[uncompliant_number])
	

