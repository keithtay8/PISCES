# PISCES RAH - Raspbian Automated Hardener

## Project Description

RAH (“Raspbian Automated Hardener”) is a tool for enhancing the security of the Raspberry Pi. As part of PISCES ("Pi Security Common Enhancements Suite"), RAH is one of three tools designed to target the Raspberry Pi running the Raspberry Pi OS (previously "Raspbian").

The Raspberry Pi is usually a physically exposed device, allowing easy access to all of its ports and storage, especially its SD Card (the main drive). The Raspberry Pi OS/Raspbian is the official operating system designed for the Raspberry Pi, made by the Raspberry Pi foundation. Due to the accessibility of the system, it has gathered a large following of users but this popularity has made it a frequent target. Security misconfigurations like insufficient permissions and missing security policies can greatly reduce the security of the Pi. It is important to ensure that these misconfigurations have been detected and resolved. This is the main goal of PISCES's RAH.

RAH is a fully-automated Hardener, aiming to ensure that the Raspberry Pi is hardened according to the CIS Benchmark (Ubuntu 20.04) and other measures. The Hardener makes use of customized scripts, which contain both the audit and remediation commands from the benchmark adapted to be fully automated. This allows the hardener to run without any user interaction (except the start). Output such as backup files and logs will be saved as by timestamps.

RAH works by looking for any ".sh" scripts to execute in the "./modules" directory. When a script is executed, each module inside can return different status messages: **"Success"** would be when remediation is needed and done successfully, **"Audit Passed"** would be when remediation is not needed, **"Ran in background"** would be when the script has been backgrounded to not hold the queue, **"Write Protection"** would be when remediation is required but is too dangerous to automatically remediate, **"Fail"** would be when no other status message has been returned.

To minimize errors, RAH's scripts must follow certain rules. Each script must define the remediation modules in them and unlike in RABS, is directly reponsible for determining the result of each module. More on these syntax rules will be covered below.

For the provided scripts, they have been tailored to specially work with RAH.
Whenever each module is first executed, the audit commands for it will first be executed if existing. If the audit is passed, the module will throw an *"Audit Passed"* before exiting. If the audit is failed, the module will procede to execute the remediation commands. Some measures may be too complicated to implement, so it will throw a *"Write Protection"* before exiting.
If a file is about to be written to, the provided scripts will first create a local backup (if it doesn't exist) before writing to the actual file as a safety mechanism. These backup files will be saved with the associated timestamped report. Note that the scanner DOES NOT PROVIDE THIS FUNCTIONALITY, it is up to the script writer to implement this themselves.

RAH is also updateable, since the remediation commands are stored as scripts *that follow a special syntax* . These scripts can be updated with more commands or new ones can be made if needed. More on this syntax will be covered in this guide.

## Table of Contents

- [Setup](#setup)
- [Usage](#usage)
- [User Guide](#user-guide)
  - [Defining the Contextual Keywords](#defining-the-contextual-keywords)
  - [Script-writing rules](#script-writing-rules)
    - [Pre-Initialization block](#pre-initialization-block)
    - [Separation of modules' outputs](#separation-of-modules-outputs)
    - [Implementing Contextual Keywords](#implementing-contextual-keywords)
  - [Backgrounding a long script](#backgrounding-a-long-script)

---

## Setup

Extract the entire archive. The top-level file directory structure should be as below:

    RABS:
        | --- <folder> mechanism
        | --- <folder> modules
        | --- <folder> reports
        | --- _launcher.sh

---

## Usage

Open a shell in your terminal application. Execute the following command:

    chmod +x <path to ‘RAH/_launcher.sh’>

View RAH's help page for execution options;

    ~/RAH/_launcher.sh -h

    PISCES RAH: A fully automated hardening script using scripts. Existing worldlists are based on the CIS hardening guide for Ubuntu 20.04 and additional Raspberry Pi OS ones. By default, a web server will be launched for customizing options.
    Syntax: _launcher.sh [-h|-n|-p <port>]

    h      Displays this help text
    n      For no Desktop, this opens a Whiptail interface via the CLI.
    p      Sets a custom Port Number for the HTTP Server. Default is 5000.

**EITHER:**
**A) Execute RAH with the default web server:**

    sudo ~/RAH/_launcher.sh

Go to `http://127.0.0.1:5000` or your device's IP address over port 5000. The web server opens the server to all devices on the local network. By default, the port is 5000 but can be changed using the "-p" flag. Toggle your options here and click the 'Submit' button when done. *NOTE: Normally '501 Internal server error' will be returned but no error has actually occurred.* Refer back to the CLI.

![Interface - Web](https://github.com/keithtay8/PISCES/blob/master/images/rah_web.png?raw=true)

**OR**
**B) Execute RAH within the CLI:**

    sudo ~/RAH/_launcher.sh -n

Select/unselect the modules to execute/unexecute. Press 'Enter' when you're done customizing.

![Interface - CLI](https://github.com/keithtay8/PISCES/blob/master/images/rah_cli.PNG?raw=true)

Once your options are locked in, RAH will procede to execute the enabled measures.

![Execution](https://github.com/keithtay8/PISCES/blob/master/images/rah_execute.PNG?raw=true)

Once execution is complete, if there are still any background modules running, an instance of 'watch' will overtake the CLI. When all backgrounded modules are finished, the 'watch' instance will self-terminate.

![Execution](https://github.com/keithtay8/PISCES/blob/master/images/rah_background.PNG?raw=true)

After execution, a summary page will be returned.

![Execution](https://github.com/keithtay8/PISCES/blob/master/images/rah_post.PNG?raw=true)

Go to the 'RAH/reports' folder and view the latest timestamped folder. It will be in the 'YYYY-MM-DD_hhmm-ss' format. All executed command outputs will be saved here as json files, while any made backup files will be stored inside the 'RAH/reports/YYYY-MM-DD_hhmm-ss/backups'.

![Execution](https://github.com/keithtay8/PISCES/blob/master/images/rah_post_2.PNG?raw=true)

---

## User Guide

RAH ("Raspbian Automated Hardener") is a tool for hardening the Raspberry Pi OS installed on a physical Raspberry Pi. It must be **ran with sudo**.

It comprises of a command execution mechanism using python ("mechanism.py") and a series of scripts pre-populated with audit & remediation commands from the CIS Benchmark for Ubuntu. When executing the main `_launcher.sh`, the script will: 1) execute `mechanism/build_config.py` which creates a `mechanism/config.json` file, 2) run the python web server or CLI, 3) Execute the scripts based on your options.

If additions/modifications to existing scripts are needed, there are rules that the script must follow to have its output properly interpreted. These will be covered later.

### Defining the Contextual Keywords

In `mechanism/mechanism.py`, there are some settings to note:

    #!/usr/bin/python

    import os
    import subprocess
    import sys
    import json
    from time import sleep

    ### Define Contextual Keywords and other settings
    ending = '<<BREAKPOINT>>'                           #ending: the delimter phrase for scripts with multiple modules
    wr_prot = '<<WR_PROT>>'                             #wr_prot: thrown string for "remediation needed but not applied due to complexity"
    audit = '<<AUDIT>>'                                 #audit: throw string for "no remediation required"

    modules_that_need_background = ['1.3.1.sh']         #Contains script names, these scripts are backgrounded immediately
    ...

**The contextual keywords must be used for every script.** They affect how the output of each script is processed and determines the status of execution. *NOTE: If any of these are changed, they must be reflected in EVERY SCRIPT. The provided scripts have defined these as variables, so changing these will be less of a hassle.*

### Script-writing rules

Below is an exercept from one of the provided scripts. This one contains multiple modules, so the contextual keyword 'ending' has to be returned after each finished module:

    #!/bin/bash
    # CIS Ubuntu 20.04
    # 4.2.1.1 Ensure rsyslog is installed (Automated);;;4.2.1.1: success
    # 4.2.1.2 Ensure rsyslog Service is enabled (Automated);;;4.2.1.2: success
    # 4.2.1.3 Ensure logging is configured (Manual);;;4.2.1.3: success
    # 4.2.1.4 Ensure rsyslog default file permissions configured (Automated);;;4.2.1.4: success
    # 4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host (Automated);;;4.2.1.5: success
    # 4.2.1.6 Ensure remote rsyslog messages are only accepted on designated log hosts. (Manual);;;4.2.1.6: success
    # 4.2.2.1 Ensure journald is configured to send logs to rsyslog (Automated);;;4.2.2.1: success
    # 4.2.2.2 Ensure journald is configured to compress large log files (Automated);;;4.2.2.2: success
    # 4.2.2.3 Ensure journald is configured to write logfiles to persistent disk (Automated);;;4.2.2.3: success
    # 4.2.3 Ensure permissions on all logfiles are configured (Automated);;;4.2.3: success

    audit='<<AUDIT>>'
    breakpoint='<<BREAKPOINT>>'
    wr_p='<<WR_P>>'

    if [[ ${BASH_ARGV:0:1} = 1 ]]; then
        if [[ ! $(dpkg -s rsyslog | grep 'install ok installed') ]]; then
            apt install rsyslog -y
            if [[ $(dpkg --list | grep rsyslog) ]]; then
                echo '4.2.1.1: success'
            fi
        else
            echo "$audit"
        fi
    fi
    echo "$breakpoint"

    if [[ ${BASH_ARGV:0:1} = 1 ]] && [[ ${BASH_ARGV:1:1} = 1 ]]; then
        if [[ ! $(systemctl is-enabled rsyslog | grep 'enabled') ]]; then
            systemctl --now enable rsyslog && echo '4.2.1.2: success'
        else
            echo "$audit"
        fi
    fi
    echo "$breakpoint"
    ...

Here is another exercept from the provided scripts. This one only contains one module, so the contextual keyword 'ending' is not required to be returned:
*NOTE: this script is backgrounded*

    #!/bin/bash
    # CIS Ubuntu 20.04
    # 1.3.1 Ensure AIDE is installed (Automated);;;1.3.1: ran

    audit='<<AUDIT>>'
    breakpoint='<<BREAKPOINT>>'
    wr_p='<<WR_P>>'

    if [[ ! $(dpkg -s aide | grep -E '(Status:|not installed)') = 'Status: install ok installed' ]] || [[ ! $(dpkg -s aide-common | grep -E '(Status:|not installed)') = 'Status: install ok installed' ]]; then
        apt install aide aide-common -y
        if (( $(dpkg --list | grep aide | wc -l) >= 2 )); then
            aideinit -y -f
        fi
    elif [[ ! $(timeout 30 aideinit | grep Overwrite) ]]; then
        aideinit -y -f
    fi

#### Pre-Initialization block

Notice that at the start of the script, there is a series of comments denoting the modules and a phrase? Before any script is being executed, the `mechanism/build_config.py` file will first read through every script to look for these lines. The `build_config.py` script will keep reading the lines until it faces a line without a leading `#` then it stops reading further. The pattern it looks out for is `#module_code module_name;;;success_message`.

Both the `module_code` and `module_name` are used for tracking purposes, while the `success_message` is the string that the RAH tries to match literally to give a 'Success' status.

#### Separation of modules' outputs

*NOTE: This section can be ignored if your script only contains 1 module.*

Since this script has multiple modules, the usage of `BASH_ARGV` is present. `BASH_ARGV` is used for retrieving the supplied arguments of a script. In the above script's case, RAH executes it as `4.2.sh 1111111111`. The supplied arguments consist of either a '0' (placeholder) or '1' (execute this). The script must then process these arguments and execute accordingly, which can be achieved using `[[ ${BASH_ARGV:(insert index here):1} = 1 ]]`. *NOTE: even if a particular module is not executed, **the contextual keyword 'ending' must still be returned** ([see 'Contextual Keywords' code block](#defining-the-contextual-keywords)) .*

You can implement loops for multiple modules within one script, but there must always have the contextual keyword 'ending' returned regardless of whether it is executed or not.

#### Implementing Contextual Keywords

For each module in any script, you must place the remediation command and throw the associated 'Success' message that you defined in the script's comment header (Eg if you used `#1.1 Test case;;;1.1: success`, you must echo `1.1: success` for the module to pass). *This is the minimum requirement.*

Optionally, you can add the contextual keyword 'audit' if you wish to do a pre-remediation check. If this pre-remediation check passes so no remediation has to be executed, you can instead throw the contextual keyword 'audit' (default: `<<AUDIT>>`). *This tells the user that no changes were made.*

Optionally alongside 'audit', you can add the contextual keyword 'wr_prot' if you wish to ask the user to manually self-remediate. If your pre-remediation check fails but it might be too risky to automate the remediation, you can instead throw the contextual keyword 'wr_prot' (default: `<<WR_PROT>>`). *This tells the user that manual remediation is required and to check the logs.*

#### Creating backup files

Before making an modifications to a file, you may first want to create a backup. During execution, RAH changes the directory to its own, so any file saved relatively will be stored here. You can do `cp '/original/path/to/file ./file.backup` or any equivalent, but it must end with the `.backup` extension. When RAH is done, RAH will move all files ending with `.backup` to the 'RAH/reports/YYYY-MM-DD_hhmm-ss/backups' folder for the appropriate timestamp.

#### Backgrounding a long script

If you have a script that is very slow, it may hold up the other modules for too long. Instead of leaving it as it is, you can choose to background this script. To do this, go to `mechanism/mechanism.py` and add the script name to the variable array `modules_that_need_background`.([see 'Contextual Keywords' code block](#defining-the-contextual-keywords))  

When you background a script, its output will no longer be monitored and RAH will instead track if its alive or not. You can have multiple backgrounded scripts running at once.

When all other modules are done executing, the backgrounded scripts will be brought into focus. If backgrounded scripts are still executing, an instance of 'watch' (refreshes every 2 seconds) will be started to track the process status of each backgrounded script via PIDs.  

![Execution](/images/rah_background.png)

Once the backgrounded script finishes execution or dies, the watch instance will self-terminate.
