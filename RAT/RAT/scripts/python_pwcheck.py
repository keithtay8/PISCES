#!/usr/bin/python3

import os, crypt


## Initialize variables
#passwords_lst=os.environ["script_dir"]+'/lists/passwords.txt'
passwords_lst=os.environ["PASSWD_SRC"]


dct, pw_lst, flagged_lst={'/etc/shadow': os.environ["PASSWD_LST"].split(';;')}, [], []
for password in open(passwords_lst,'r'):
	pw_lst.append(password)


## If passwd contains hashes
if os.environ["ETC_PASSWD_LST"]:
	temp=os.environ["ETC_PASSWD_LST"].split(';;')
	while True:
		if '' in temp:
			temp.remove('')
		else:
			break
	dct['/etc/passwd']=temp


## Program
for file in dct:
	lst=dct[file]
	flagged_lst.append(file+':')
	for line in lst:
		# Format of line_lst: ["username","hash"]
		line_lst=line.split('::')

		# Splitting the hash from line_lst
		algo_salt_lst=line_lst[1].split('$')
		
		if algo_salt_lst[1] == 'y' or algo_salt_lst[1] == 'gy':
			algo_salt="${0}${1}${2}".format(algo_salt_lst[1], algo_salt_lst[2], algo_salt_lst[3])
		else:
			algo_salt="${0}${1}$".format(algo_salt_lst[1], algo_salt_lst[2])
		
		for password in pw_lst:
			# Clobber to remove line breaks, will affect algorithm
			password=password.rstrip()
			
			generated=crypt.crypt(password, algo_salt)
			if generated == line_lst[1]:
				flagged_lst.append('{0}::{1}'.format(line_lst[0], password))
				break

print(';;'.join(flagged_lst))
