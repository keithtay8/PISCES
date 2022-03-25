#!/usr/bin/python

import json
import os
from flask import Flask, render_template, request
import sys

os.chdir(os.path.dirname(os.path.realpath(__file__)))
if len(sys.argv) > 1:
	port=sys.argv[1]

json_file = open("../config.json")
dct = json.load(json_file)
json_file.close()

reference_lst = {'1': 'Initial Setup', '2': 'Services', '3': 'Network Configuration', '4': 'Logging and Auditing', '5': 'Access, Authentication and Authorization', '6': 'System Maintenance', 'P1': 'Pi-Specific patches', 'NIL': 'Others'}
dct_2 = {}
for key in dct:
    matching_key = key.split('.', 1)[0]
    if matching_key not in dct_2.keys():
        if matching_key in reference_lst:
                dct_2[matching_key] = {key: dct[key]}
        elif 'NIL' not in dct_2.keys():
                dct_2['NIL'] = {key: dct[key]}
        else:
                dct_2['NIL'].update({key: dct[key]})
    else:
        dct_2[matching_key].update({key: dct[key]})

app = Flask(__name__, template_folder=os.path.join(os.getcwd(), 'templates'), static_folder=os.path.join(os.getcwd(), 'templates'))
@app.route('/', methods=['GET', 'POST'])
def home():
    if request.method == 'POST':
        print(request.form)
        for module in dct:
            if module not in list(request.form):
                dct[module][-1] = False
            else:
                dct[module][-1] = True
        target = open('../config.json', 'w')
        json.dump(dct, target, indent=4)
        target.close()
        func = request.environ.get('werkzeug.server.shutdown')
        if func is None:
            raise RuntimeError('Not running with the Werkzeug Server')
        func()
    else:
        return render_template('page.html', dct=dct_2, reference_lst=reference_lst)

from jinja2 import Environment, FileSystemLoader, select_autoescape
env = Environment(loader=FileSystemLoader('templates'), trim_blocks=True, lstrip_blocks=True, autoescape=select_autoescape())
app.run(port=port, host="0.0.0.0")
