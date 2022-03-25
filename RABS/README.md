# PISCES RABS - Raspbian Automated Baseline Scanner

## Project Description

RABS (“Raspbian Automated Baseline Scanner”) is a tool for checking the security of the Raspberry Pi. As part of PISCES ("Pi Security Common Enhancements Suite"), RABS is one of three tools designed to target the Raspberry Pi running the Raspberry Pi OS (previously "Raspbian").

The Raspberry Pi is usually a physically exposed device, allowing easy access to all of its ports and storage, especially its SD Card (the main drive). The Raspberry Pi OS/Raspbian is the official operating system designed for the Raspberry Pi, made by the Raspberry Pi foundation. Due to the accessibility of the system, it has gathered a large following of users but this popularity has made it a frequent target. Security misconfigurations like insufficient permissions and missing security policies can greatly reduce the security of the Pi. It is important to ensure that the Raspberry Pi OS is hardened according to a benchmark as a baseline. This is the main goal of PISCES's RABS.

RABS is a Baseline Scanner, aiming to ensure that the Raspberry Pi is hardened according to the CIS Benchmark (Ubuntu 20.04). The scanner makes use of wordlists, which contain audit commands from the benchmark adapted to be fully automated. This allows the scanner to run without any user interaction (except the start). Output will be saved as a timestamped HTML report.

RABS is also updateable, since the audit commands are stored in plaintext files *that follow a special syntax* . The plaintext wordlists can be updated with more commands or new ones can be made if needed. More on this syntax will be covered in this guide.

## Table of Contents

- [Setup](#setup)
- [Usage](#usage)
- [User Guide](#user-guide)
  - [HTML Report](#html-report)
  - [Header](#header)
  - [Audit commands](#audit-commands)
  - [Rules](#rules)

---

## Setup

Extract the entire archive. The top-level file directory structure should be as below:

    RABS:
        | --- <folder> Reports
        | --- <folder> jinja2
        | --- <folder> Jinja2-3.0.3.dist-info
        | --- <folder> markupsafe
        | --- <folder> MarkupSafe-2.0.1.dist-info
        | --- <folder> modules
        | --- make_index.py
        | --- scanner.py
        | --- _launcher.sh

---

## Usage

Open a shell in your terminal application. Execute the following command:

    chmod +x <path to ‘RABS/_launcher.sh’>

View RABS' help page for execution options;

    ~/RABS/_launcher.sh -h

    PISCES RABS: A fully automated scanner designed to read certain wordlists, execute their contents and check the results. Existing worldlists based on CIS Benchmark for Ubuntu 20.04.
    Syntax: _launcher.sh [-h|v]

    h      Displays this help text
    v      Returns verbose output into the CLI

Execute RABS:

    sudo ~/RABS/_launcher.sh

Go to 'RABS/Reports' and get the latest timestamped folder. All the results will be saved and templated as HTML reports here. In the 'RABS/Reports/YYYY-MM-DD_hhmm-ss/dumps' folder, all the command outputs will be saved in txt files.

---

## User Guide

RABS ("Raspbian Automated Baseline Scanner") is a tool for scanning the Raspberry Pi OS installed on a physical Raspberry Pi. It must be **ran with sudo**.

It comprises of a command execution mechanism using python ("scanner.py") and a series of wordlists populated with audit commands from the CIS Benchmark for Ubuntu. When executing the main "_launcher.sh", the script will first look for all wordlists with a certain naming convention (eg '1.2.txt', '3.4.5.6.txt') in the "modules" folder. Each of these wordlists contain 1) the audit commands to execute and 2) the expected response, both which follow a unique syntax.

By default, the scanner doesn't run in verbose mode, and will only print messages before the start of each series (ie "Chapter 1" for the "1.x.txt" wordlists, etc). If updates/changes to the wordlists are needed, there are a few steps to follow. These will be covered now.

### HTML Report

![Saved Report - Index](https://github.com/keithtay8/PISCES/blob/master/images/rabs_index.PNG?raw=true)

![Saved Report - Page](https://github.com/keithtay8/PISCES/blob/master/images/rabs_page.PNG?raw=true)

![Saved Report - Page](https://github.com/keithtay8/PISCES/blob/master/images/rabs_page_expand.PNG?raw=true)

![Saved Report - Page](https://github.com/keithtay8/PISCES/blob/master/images/rabs_page_expand_show.PNG?raw=true)

### Audit wordlist format

Wordlists must be in *plaintext '.txt' files* with names that can only contain *numbers* ['0-9'] and *periods* ['.']. **The filename must always start with a number and in the format '0.1.txt' minimally (0 and 1 must be numbers)**. They *must be located in the './modules' directory as well.*  

    Valid filenames: '1.2.3.txt' '1.2.txt' '9.0.txt'

    Invalid filenames: 
        '1.txt' :       Must have a number following the first period, eg '1.[0-9].txt' is valid
        'A2.1.txt':     Filename cannot start with an alphabet, eg '2.1.txt' is valid
        '1.2.sh':       File extension must be '.txt', scripts ('.sh', '.py') can be *only be called as an audit command*, eg '1.2.txt' is valid

To write a wordlist, they must follow a certain syntax. Below is a sample extract:

    ### NAME OF COMMAND SET
    ### Comments are prefixed with '#' so here is a sample comment line, but:
    ### FIRST LINE IS NEVER A COMMENT EVEN WITH '#', BUT MUST BE PREFIXED WITH '###'

    # Sample structure
    [0.1.2.1 || Name || Automated/Manual]{Active/Inactive}
    <AUDIT_COMMAND_1>
        <EXPECTED_OUTPUT>
    <AUDIT_COMMAND_2>
        <EXPECTED_OUTPUT>
        <EXPECTED_OUTPUT_2>
    <AUDIT_COMMAND_3>
        <No spacing between AUDIT_COMMAND entries for NO_OUTPUT_EXPECTED>
    <AUDIT_COMMAND_4>
        <BLANK,should not be processed>
    <AUDIT_COMMAND_5>
        ~   <REGEX_PATTERN>


    [0.1.2.2 || Name || Automated/Manual]{Active/Inactive}
    <AUDIT_COMMAND_1>
        <OPTIONAL_OUTPUT_TO_EXPECT>


    <0.1.2.2>[0.1.2.3 || Name || Automated/Manual]{Active/Inactive}
    <EXECUTE_AUDIT_COMMAND_1_IF_0.1.2.2_PASSED>
        <OPTIONAL_OUTPUT_TO_EXPECT>

In each wordlist, the audit commands are grouped as **modules**. Each module consists of three parts: the **header**, the **audit commands**, and their **rules**. Each audit command can have as many rules as the writer prefers for matching against the results of executing this audit command. If all rules are matched, then this module is regarded as a 'successful audit', else a 'failed' result will be returned.  
Here's a quick breakdown of the components!

#### Header

For each set of audit commands, the first line is a **header**. A header contains the name and the unique code for this set of audit commands. Each header must hold at least one audit command but there is no limit to how many can be executed under one header. There MUST BE SPACES surrounding every double pipe ["||"], the format is below:

    [MODULE CODE || NAME OF AUDIT COMMAND || Automated/Manual]{Active/Inactive}

    MODULE CODE:            Must be purely numbers ["0-9"] and separated by periods ["."]. The first few characters of the MODULE CODE must match the filename. Eg if filename is "1.2.txt", MODULE CODE must be prefixed with "1.2"
    NAME OF AUDIT COMMAND:  Create/place a name for this audit set here, accepts any character EXCEPT pipes ["|"]. Prefix the name with '(!)' to indicate for 'user review', audit commands will be executed but returned directly without any review processing, any rules will be ignored.
    Automated/Manual:       Either 'Automated' or 'Manual', for naming purposes so doesn't affect anything
    {Active/Inactive}:      Affects whether this set will be ran or not. 'Active' activates so while anything else doesn't

    Valid:
        [1.2 || My first audit || Automated]{Active}
        [4.15.1 || Next audit || Manual]{Active}
        [12.13.1 || Fin4l Aud1t || Automated]{Inactive}
        [1.2 || Fin4l Aud1t || Automated]{not active}

    Invalid:
        [1 || Number One audit || Automated]{Active}:   MODULE_CODE is too short, there must be at least a period, eg '1.1'
        [1.2|| Another problem||Manual]{Active}:        No whitespaces surrounding all the double pipes
        [1A.2 || Pass maybe || Manual]{Inactive}:       MODULE_CODE contains letters
        [ 22.2 || This || Manual]{Active}:              Whitespace after the left bracket [ "[" ]

#### Audit commands

Under every header, the **audit commands** are listed. The audit commands are listed under each header, separated by a newline. *They cannot spread across multiple lines*. They must either be inline commands, or paths to your executable audit script (and arguments if needed). An example is below:

    [1.2.3 || Sample || Automated]{Automated}
    [[ -f '/etc/passwd' ]] && echo 'Passed!' || echo '/etc/passwd/ is missing!'
        sample_rule
    ./my_custom_script.sh
        sample_rule

    Valid:
    [[ -f '/etc/shadow' ]] && echo $?
    modprobe -n -v cramfs | grep -E '(cramfs|install)'
    /absolute/path/to/execute/script.sh
    ./relative/paths/work.py

    Invalid:
    if [[ 1 = 1 ]]; then        }
        echo "It's True!"       } Multiple-line commands will not work, please make them inline or save them to a callable script
    fi                          }

#### Rules

Under each audit command, the rules will be placed here. They must be directly under their corresponding audit command, and prefix with a tab space. If only prefixed with a tab space, then the rule will be treated as an absolute 'string' to match. An example is below:

    [1.2.3 || Sample || Automated]{Automated}
    [[ -f '/etc/passwd' ]] && echo 'Passed!' || echo '/etc/passwd/ is missing!'
        Passed!
    ./my_custom_script.sh
        Files have been audited!
        Users are in order!

    CASE 1: If the first audit command returns any line that only contains 'Passed!', then the rule of 'Passed!' is matched and an overall success will be returned
    CASE 2: If the second audit command returns multiple lines but has the line 'Files have been audited!', the first rule will be passed. However, if the second rule cannot find an exact line of 'Users are in order!', an overall fail will be returned

Audit commands may also return no outputs in certain situations. If this is no expected output, then you can indicate that as a rule as well:

    [1.2.3 || Sample || Automated]{Automated}
    [[ -f '/etc/passwd' ]] && echo 'Passed!' || echo '/etc/passwd/ is missing!'
        Passed!
    ./my_custom_script.sh
    [[ grep 'password' '/var/special.log' ]] && echo 'Found'
        Found
    [[ ! -d './etc' ]] && echo '/etc/ doesn't exist'
    
    CASE 1: The first audit command runs, and matches one rule: the literal string 'Passed!'
    CASE 2: The second audit command runs the './my_custom_script.sh', but since no rules or indented lines follow it, then *no output is expected*. If any output is returned, a fail condition is issued, else a pass condition is issued
    CASE 3: The third audit command runs, and matches one rule: the literal string 'Found'
    CASE 4: The fourth audit command runs, but since there is no following indented line, no output is expected to issue a 'pass'

If your output is more dynamic in nature, you can make use of regular expressions to match any unusual outputs. To do so, prefix your line with a `<tab>~<tab>` where `<tab>` is a tab space. Each pattern will be wrapped in '^' and '$' before executing EXCEPT if '(?' prefixes the pattern (pattern will then not be wrapped). The rule will be compared against every line of the output, and if a match is found then a 'success' will be returned:

    [1.2.3 || Sample || Automated]{Automated}
    grep 'password' /var/auth.log
        ~   .+present.+
    ./my_custom_script.sh
        ~   passcode:[\s]+key_[a-zA-Z0-9]
    [[ ! -d './etc' ]] && echo '/etc/ doesn't exist'
        ~   (?=.*lol)keyword
    ./another_script.sh
        ~   .+

    CASE 1: The first audit command runs, after wrapping the rule is '^.+present.+$' which will match against any line that has the string 'present' in it
    CASE 2: The second audit command runs, after wrapping the rule is '^passcode:[\s]+key_[a-zA-Z0-9]$' which matches any line that has the string 'passcode:<any space amount>key_<alphanumeric string>
    CASE 3: The third audit command runs, since there is a '(?' prefix in the pattern the rule is not wrapped, and will be interpreted as a literal rule
    CASE 4: The fourth audit command runs, the rule matches to anything, so as long as output is returned a pass will be issued

### Title configuration for HTML

If you would to update the chapter headings for each set of modules, you can modify the 'config.json' file. *This file must be edited if you have added a new chapter of modules.* Modules are grouped by the first string before the first period (eg '1.1.1.1' is under '1', '2.3.4' is under '2', '12.2.0' is under '12'). Below are its default contents:

    {
        "1": "Initial Setup",
        "2": "Services",
        "3": "Network Configuration",
        "4": "Logging And Auditing",
        "5": "Access, Authentication And Authorization",
        "6": "System Maintenance"
    }

You can add new titles here as well, as long as the key is an integer but it doesn't have to be in order (eg keys can be '1', '2', '11', '12', '13', ascending is preferable). If 'config.json' or 'index.txt' is deleted, they will be regenerated.
