#!/bin/usr/python

import sys
import json
from jinja2 import Environment, FileSystemLoader, select_autoescape
import os

if len(sys.argv) < 4:
	exit()

# Parse report into json for later
import markupsafe

report_dct = {}
with open(sys.argv[1], 'r') as report_name:
    lookup_dct = {
        'os_lst': {
            'OS': 'get_osinfo',
            'Networking': 'get_networkinfo',
            'Filesystem': 'get_filesystem',
            'Cron Tasks': 'get_cron',
            'Display Outputs': 'get_display',
            'Development Tools': 'get_languages',
            'Find ENV variables': 'get_envvar'
        },
        'ur_lst': {
            'Identified users': 'return_allusers',
            'Checking permissions for all non-system users\' directories': 'test_userdir',
            'Checking if default users are locked': 'check_defaultUsers',
            'Searching for non-owner\'s files': 'check_directory_rootowner'
        },
        'pv_lst': {
            'Checking permissions on system files': 'check_privileged',
            'Checking sensitive system files': 'check_privfiles',
            'Checking /var/log and home directory contents for keywords': 'check_logs'
        },
        'xr_lst': {
            'Checking password hashes against common passwords': 'checkSetPasswords',
            'Checking for certain installed packages': 'checkRecommendedPackages',
            'Checking certain installed packages\' configs': 'checkRecommendedPackages_configs',
            'Checking for Docker folders & configs': 'checkDocker',
            'GUI USB Automounting': 'gui_automount',
            'Video output checks': 'gui_display',
            'Audio': 'audio_output',
            'AppArmor (Raspbian)': 'apparmor_raspbian',
            'Startup UI': 'startup_mode',
            'Raspbian-configurable Services & Interfaces': 'pi_services_interfaces'
        }
    }
    for line in report_name.readlines():
        line = line.rstrip()
        if not line:
            continue
        if line[0:3] == '===' and line[-3:] == '===':
            for a_dct_of_type_checks in lookup_dct.values():
                for a_label_to_match in a_dct_of_type_checks:
                    if a_label_to_match.lower() in line.lower():
                        key = list(lookup_dct.keys())[list(lookup_dct.values()).index(a_dct_of_type_checks)]
                        if key not in report_dct:
                            report_dct[key] = {
                                a_dct_of_type_checks[a_label_to_match]: {'title': a_label_to_match, 'contents': {}}
                            }
                        else:
                            report_dct[key][a_dct_of_type_checks[a_label_to_match]] = {
                                'title': a_label_to_match, 'contents': {}
                            }
        else:
            # Find last key of outer dct and inner dct to always get the latest entry added
            temp = [list(report_dct.keys())[-1], '', '']
            temp[1] = list(report_dct[temp[0]].keys())[-1]
            if line[0] == '-' and line[-1] == '-':
                if line[2:-2] not in report_dct[temp[0]][temp[1]]['contents']:
                    report_dct[temp[0]][temp[1]]['contents'][line[2:-2]] = []
                continue
            # layout>>> key_lst = [last key in report_dct, last key in here[0]]
            if not report_dct[temp[0]][temp[1]]['contents'].keys():
                continue
            temp[2] = list(report_dct[temp[0]][temp[1]]['contents'].keys())[-1]
            temp2 = (report_dct[temp[0]])[temp[1]]['contents'][temp[2]]
            temp2.append(line)
            report_dct[temp[0]][temp[1]]['contents'][temp[2]] = temp2

target = open(sys.argv[2] + '/scripts/html_templating/dump.json', 'w')
json.dump(report_dct, target, indent=4)
target.close()


json_file = open(sys.argv[2] + '/scripts/html_templating/dump.json')
universal_results = json.load(json_file)
json_file.close()

date = os.listdir(sys.argv[2] + '/reports')[-1].split('-')
date = date[:2] + [date[2].split('_')[0], date[2].split('_')[1][:2] + ':' + date[2].split('_')[1][:2]] + date[3:]
date = '%s/%s/%s %s:%s' % tuple(date)
info_dct = {'Date': date, 'Hostname': os.uname()[1], 'User': sys.argv[3]}


env = Environment(loader=FileSystemLoader(sys.argv[2] + '/scripts/html_templating/templates'), trim_blocks=True, lstrip_blocks=True, autoescape=select_autoescape())
template = env.get_template('page.html')
output_from_parsed_template = template.render(dct=universal_results, info_dct=info_dct)

# to save the results
with open(sys.argv[2] + '/scripts/html_templating/templates/RAT.html', "w") as fh:
    fh.write(output_from_parsed_template)
