# PISCES RAT - Raspbian Assessment Tool

## Project Description

RAT (“Raspbian Assessment Tool”) is a tool for checking the security of the Raspberry Pi. As part of PISCES ("Pi Security Common Enhancements Suite"), RAT is one of three tools designed to target the Raspberry Pi running the Raspberry Pi OS (previously "Raspbian").

The Raspberry Pi is usually a physically exposed device, allowing easy access to all of its ports and storage, especially its SD Card (the main drive). The Raspberry Pi OS/Raspbian is the official operating system designed for the Raspberry Pi, made by the Raspberry Pi foundation. Due to the accessibility of the system, it has gathered a large following of users but this popularity has made it a frequent target. Common misconfigurations like default passwords and insufficient permissions greatly reduce the security of the Pi. It is important to check if such misconfigurations exist. This is the main goal of PISCES's RAT.

RAT is a Raspberry Pi OS-targetted scanner, aiming to scan for the presence of common misconfigurations. It comprises of scripts split among 4 different areas: OS-Related, User-Related, Privileged Files, Pi-specific Scripts. Without relevant arguments, **all scripts except the OS-Related scripts will be executed**. With relevant arguments, PISCES will only run the supplied ones.  

By default, **output is returned as text output via CLI**, but can be saved as a HTML report.  

*Note: During execution, there may be messages starting with ‘**[INFORMATION]**’ returned. These messages are just ‘informational’ and do not indicate an error.*

## Table of contents

- [Setup](#setup)
- [Usage](#usage)
- [User Guide](#user-guide)
  - [OS-Related](#os-related)
  - [User-Related](#user-related)
  - [Privileged Files](#privileged-files)
  - [Pi-Specific scripts](#pi-specific-scripts)
- [HTML Report](#html-report)
- [Customizing](#customizing)

---

## Setup

Extract the entire archive. The top-level file directory structure should be as below:

    RAT:
        | --- <folder> lists
        | --- <folder> reports
        | --- <folder> scripts
        | --- osinfo.sh
        | --- package_txt.py
        | --- piscripts.sh
        | --- privinfo.sh
        | --- python_pwcheck.py
        | --- usersinfo.sh
        | --- _launcher.sh

---

## Usage

Open a shell in your terminal application. Execute the following command:

    chmod +x <path to ‘RAT/_launcher.sh’>

View RAT' help page for execution options;

    ~/RAT/_launcher.sh -h

    PISCES RAT: Collection of modular scripts to enmuerate (Raspberry) Pi system configurations, test and output results. No option requires an input.
    Syntax: _launcher.sh [-h|v|o|H] [-o|u|p|s]

    h      Displays this help text
    O      Saves output into the relative 'reports' directory
    [Optional] Choose which scripts to run (chainable, eg -op):
    o      Enable OS-related enumeration scripts, disabled by default
    u      Enable scanning of User-related areas
    p      Enable scanning in certain privileged files
    s      Enable Pi-specific scanning scripts, made by me
    a      Activates ALL the above options ('oups' only)

Execute RAT ("a" for **all**, "O" for **HTML Output**):

    sudo ~/RAT/_launcher.sh -aO

---

## User Guide

RAT (“Raspbian Assessment Tool”) is developed as a tool for checking the security of the Raspberry Pi. It must be **ran with sudo**.  

It comprises of scripts split among 4 different areas: OS-Related, User-Related, Privileged Files, Pi-specific Scripts. Without relevant arguments, **all scripts except the OS-Related scripts will be executed**. With relevant arguments, RAT will only run the supplied ones.  

By default, **output is returned as text output via CLI**, but can be saved as a HTML report.  

*Note: During execution, there may be messages starting with ‘**[INFORMATION]**’ returned. These messages are just ‘informational’ and do not indicate an error.*

### OS-Related

Scripts in this section are designed to run commands and read files to enumerate information about the host Operating System. Most scripts are designed by me, while the rest were from other popular scanners such as “Linuxprivchecker.py” and “linPEAS”.

Scripts in this section will:

- Get operating system version, kernel version, and the device hostname
- Get Network interface addresses, the Network routing table, and Open ports
- Read '/etc/fstab', '/proc/mounts'
- Get the cron jobs
- Get all available display outputs for every user with a valid login shell
- Check if certain programming languages exist
- Retrieve ENV variables

(Snipped) Sample Output:

    pi@raspberry: sudo ~/RAT/_launcher.sh -o

    [INFORMATION] OS-related scripts on
    [INFORMATION] An entry's GECOS in '/etc/passwd' is empty, replacing with ',,,' for now
    === OS ===
    - Operating System -
    Operating System: "Debian GNU/Linux 11 (bullseye)"
    Kernel version: Linux version 5.10.92-v8+ (dom@buildbot) (aarch64-linux-gnu-gcc-8 (Ubuntu/Linaro 8.4.0-3ubuntu1) 8.4.0, GNU ld (GNU Binutils for Ubuntu) 2.34) #1514 SMP PREEMPT Mon Jan 17 17:39:38 GMT 2022
    Hostname: raspberrypi

    === NETWORKING ===
    - All Network Interfaces -
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
        valid_lft forever preferred_lft forever
    ...

    - Network Routing Table -
    Kernel IP routing table
    Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
    0.0.0.0         192.168.137.1   0.0.0.0         UG        0 0          0 eth0
    ...

    - Open ports -
    tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      643/sshd: /usr/sbin
    ...

    === FILESYSTEM ===
    - Filesystem Table (/etc/fstab) -
    </etc/fstab contents>

    - Mounts: -
    /dev/mmcblk0p2 on / type ext4 (rw,noatime)
    devtmpfs on /dev type devtmpfs (rw,relatime,size=1777352k,nr_inodes=444338,mode=755)
    proc on /proc type proc (rw,relatime)
    ...
    Boot partition is READ-ONLY                

    === CRON TASKS ===
    - Scheduled cron jobs -
    -rw-r----- 1 root root    0 Mar  9 17:29 /etc/cron.allow
    ...

    - Writeable cron directories -
    <Writeable cron directories go here>

    - Users' cron jobs -
    0 5 * * * /usr/bin/job --dummy

    === DISPLAY OUTPUTS ===
    - root -
    No detected displays
    - pi -
    No detected displays
    - other_user -
    No detected displays

    === DEVELOPMENT TOOLS ===
    - Fetch installed programming languages -
    /usr/bin/awk
    /usr/bin/perl
    ...

    === Find ENV variables ===
    - All current ENV variables -
    SHELL=/bin/bash
    SUDO_GID=1000
    ...

    [END] PISCES execution complete

### User-Related

Scripts in this section are designed to run commands and read files in every user's (who has a valid login shell). These scripts will target every user, looking through their directories to check for properly configured permissions and files owned by other users.

Scripts in this section will:

- Checks for default users (pi, root) and performs tests on them
- Retrieves all users (with a valid login shell) with their groups, UIDs & GIDs, home directories, and login shells
- Per user, check their directories for:  
  - Permissions of user-specific sensitive files (.ssh, .bashrc, .Xauthority, etc)
  - Any files that are not owned by this user (ie Files in '/home/pi' that belong to 'root')

(Snipped) Sample Output:

    pi@raspberry: sudo ~/PISCES/_launcher.sh -u

    [INFORMATION] User-Related scripts enabled
    [INFORMATION] An entry's GECOS in '/etc/passwd' is empty, replacing with ',,,' for now
    === Identified users ===
    - Users with valid shells -
    Username  UID   GID   Directory       Shell
    root      0     0     /root           /bin/bash
    pi        1000  1000  /home/pi        /bin/bash
    ...

    - Groups memberships -
    Username  Groups
    pi        pi:1000        adm:4        dialout:20  cdrom:24  sudo:27  audio:29  video:44  plugdev:46  games:60  users:100  input:105  netdev:109  spi:999  i2c:998  gpio:997  lpadmin:116
    root      root:0         lpadmin:116
    ...

    === Checking permissions for all non-system users' directories ===
    -                     Directory:  /home/pi     -
    FILE                  COMPLIANCE  RECMD(O)     DETECTED
    .bash_history         FOUND,GOOD  ---          -rw-------
    .bashrc               FOUND,GOOD  r--          -rw-r--r--
    .dmrc                 FOUND,GOOD  r--          -rw-r--r--
    .forward              MISSING     ---
    .ICEauthority         MISSING     ---
    .bash_logout          FOUND,GOOD  r--          -rw-r--r--
    .my.cnf               MISSING     ---
    .profile              FOUND,GOOD  r--          -rw-r--r--
    .python_history       FOUND,GOOD  ---          -rw-------
    .ssh                  FOUND,GOOD  ---          drwx------
    .wget-hsts            FOUND,BAD   ---          -rw-r--r--
    .Xauthority           FOUND,GOOD  ---          -rw-------
    .xsession-errors.old  FOUND,GOOD  ---          -rw-------
    .xsession-errors      FOUND,GOOD  ---          -rw-------
    -                     Directory:  /root        -
    FILE                  COMPLIANCE  RECMD(O)     DETECTED
    .bash_history         FOUND,GOOD  ---          -rw-------
    .forward              MISSING     ---
    .ICEauthority         MISSING     ---
    .*_logout             MISSING     r--
    .my.cnf               MISSING     ---
    .profile              FOUND,GOOD  r--          -rw-r--r--
    .python_history       FOUND,GOOD  ---          -rw-------
    .bashrc               FOUND,GOOD  r--          -rw-r--r--
    .ssh                  MISSING     ---
    .wget-hsts            MISSING     ---
    .Xauthority           MISSING     ---
    .xsession-errors*     MISSING     ---
    ...

    === Checking if default users are locked ===
    - Default Users: root pi -
    PASSWORD_LOGIN:
    |---pi
    Disabled:
    |---root
    VALID_SHELLS:
    |---pi              /bin/bash
    VALID_DIRECTORIES:
    |---pi              /home/pi   Exists

    === Searching for non-owner's files in homes ===
    - root (/root) -
    - pi (/home/pi) -
    -rwsr-xr-x root root .local/share/Trash/files/script.sh
    -rw-r--r-- root root .local/share/Trash/files/info.json
    ...

    [END] RAT execution complete

### Privileged Files

Scripts in this section are designed to run commands and read files in privileged areas. They check for permissions and the contents of certain files.

Scripts in this section will:

- In /etc/passwd, every password hash is the strongest (for the available version)
- In /etc/sudoers, search for 'NOPASSWD:ALL' throughout the file and its identified links
- Checks permissions on certain system files

(Snipped) Sample Output:

    pi@raspberry: sudo ~/RAT/_launcher.sh -u

    [INFORMATION] Heavier-Privileged scripts enabled
    [INFORMATION] An entry's GECOS in '/etc/passwd' is empty, replacing with ',,,' for now
    === Checking permissions on system files ===
    - Permissions -
    FILE          COMPLIANCE  RECMD(O)  DETECTED
    /etc/crontab  BAD         ---       -rw-r--r--
    /etc/shadow   GOOD        ---       -rw-r-----
    /etc/sudoers  GOOD        ---       -r--r-----
    /etc/cron.d   BAD         ---       drwxr-xr-x
    /var/log      BAD         r--       drwxr-xr-x
    /etc/fstab    GOOD        r--       -rw-r--r--
    /etc/group    GOOD        r--       -rw-r--r--
    /etc/passwd   GOOD        r--       -rw-r--r--
    /etc/profile  GOOD        r--       -rw-r--r--

    === Checking sensitive system files ===
    - /etc/shadow entries -j
    USERNAME  ALGORITHM         HASH
    root      LOCKED
    pi        SHA-512(Default)
    ...

    - /etc/sudoers entries -
    Identified links: /etc/sudoers, /etc/sudoers.d/010_at-export, /etc/sudoers.d/010_pi-nopasswd, /etc/sudoers.d/010_proxy, /etc/sudoers.d/README
    SOURCE                          LINE
    /etc/sudoers.d/010_pi-nopasswd  pi    ALL=(ALL)  NOPASSWD:  ALL
    ...

    [END] RAT execution complete

### Pi-Specific scripts

Scripts in this section are designed to run commands and read files in Raspbian-specific areas. These scripts are targetting a Raspberry Pi running 'Rapberry Pi OS/Raspbian'. Scripts here are a mix of my own creation and others derived from Raspbian's pre-bundled 'raspi-config' tool.

Scripts in this section will:

- Password Hash breaker using a wordlist of default passwords ('./lists/passwords.txt')
- Boot-related
  - Detect if booting into CLI directly instead of the Destop
  - If Pi will autologin into CLI and/or Desktop
  - If Network Boot and Splashscreen are enabled
  - Apparmor
    - Installation status & apparmor profiles info
    - Configured in '/boot/config.txt'
  - Interfaces running at startup
    - SSH, Real(VNC), Camera, GPIO remote server access, etc
  - Desktop (GUI)-related
    - Display driver, HDMI & Composite status
    - Removable Volume automounting for every user
  - Package Checker
    - Checks for certain packages installations and if their config files contain the specified rules, based on a wordlist ('./lists/packages.txt')

(Snipped) Sample Output:

    pi@raspberry: sudo ~/RAT/_launcher.sh -s

    === Checking password hashes against common passwords ===
    - Cracked passwords -
    /etc/shadow
    |     USERNAME  PASSWORD
    |---  pi        raspberry
    ...

    3/3 user(s)' passwords obtained, compared against list of 11 passwords

    === Checking for certain installed packages ===
    - Recommended packages -
    PACKAGE_NAME         INSTALLED
    fail2ban             TRUE
    unattended-upgrades  TRUE
    ufw                  TRUE
    psad                 TRUE

    4/4                  packages   installed

    === Checking certain installed packages' configs ===
    - Package config scanner results -
    fail2ban 
    |  1/1 files are compliant
    |---  /etc/fail2ban/jail.local                   COMPLIANT                     
    unattended-upgrades 
    |  0/1 files are compliant
    |---  /etc/apt/apt.conf.d/50unattended-upgrades  UNCOMPLIANT  1 unmatched lines
    ufw 
    |  3/4 files are compliant
    |---  /etc/default/ufw                           COMPLIANT                     
    |---  /etc/ufw/user.rules                        COMPLIANT                     
    |---  /etc/ufw/user6.rules                       NIL                           
    |---  /etc/ufw/ufw.conf                          UNCOMPLIANT  1 unmatched lines
    psad 
    |  1/1 files are compliant
    |---  /etc/psad/psad.conf                        NIL                           

    === GUI USB Automounting ===
    - Checking if GUI automount is disabled globally -
    User      Dir             Violations
    pi        /home/pi        mount_on_startup      mount_removable  autorun
    root      /root           pcmanfm.conf_missing
    ...

    === Video output checks ===
    - (Bootloader) OpenGL Driver -
    No detected GL Driver
    - HDMI -
    (!) HDMI is on - Run "vcgencmd display_power=0" at startup via a cronjob, rc.local, etc

    - Composite -
    Number of displays: 0
    (!) "tvservice" not supported, please manually confirm if composite output is still available. You can also follow the below Recommended solution and rerun the program

    Recommended solution: Modify '/boot/config.txt' to replace/include 'dtoverlay=vc4-fkms-v3d' (and do the above)

    === Audio ===
    - Audio outputs -
    card 0: AudioPCI [Ensoniq AudioPCI], device 0: ES1371/1 [ES1371 DAC2/ADC]
    card 0: AudioPCI [Ensoniq AudioPCI], device 1: ES1371/2 [ES1371 DAC1]

    === AppArmor (Raspbian) ===
    - Installation Status -
    Status: install ok installed

    - In Bootloader Configuration Status -
    (!)Not configured at Startup, add 'apparmor=1 security=apparmor' to '/proc/cmdline'

    - AppArmor Profile Status -
    18 profiles are loaded.
    16 profiles are in enforce mode.
    2 profiles are in complain mode.
    4 processes have profiles defined.

    === Startup UI ===
    - Boot-into mode -
    (!) Booting to Desktop by default, please boot into CLI instead
    - Auto Login -
    (!) CLI as pi
    (!) Desktop GUI as pi
    - Network Boot -
    Waiting for network on boot: False
    - Splash Screen -
    Splash Screen: False

    === Raspbian-configurable Services & Interfaces ===
    - (raspi-config) Services and Interfaces  -
    SSH disabled
    (Real)VNC disabled
    SPI disabled
    I2C disabled
    One-wire disabled
    Serial disabled
    GPIO Remote server access disabled

    [END] RAT execution complete

---

## HTML Report

![OS Tab - HTML](https://github.com/keithtay8/PISCES/blob/master/images/html_os.PNG?raw=true)

![User Tab - HTML](https://github.com/keithtay8/PISCES/blob/master/images/html_user.PNG?raw=true)

![Privileged Files Tab - HTML](https://github.com/keithtay8/PISCES/blob/master/images/html_priv.PNG?raw=true)

![Pi-Specific Tab - HTML](https://github.com/keithtay8/PISCES/blob/master/images/html_pi-spec.PNG?raw=true)

---

## Customizing

There are some customizable options.

### One set is in the '**_launcher.sh**'.

![Confiugurable Options - Launcher](https://github.com/keithtay8/PISCES/blob/master/images/launcher_opts.PNG?raw=true)

From 'usersinfo.sh':

- checklist: Used for validating specific files & folders in **each user's directory**, it compares the 'Others' permission bits against the target files'. Can add multiple entries per permission combination, use only *relative* file pathing.

```bash
Format:
["r-x"]="filename1 file_name2 ./file/name3"
["rwx"]="filename4"

Default:
["---"]=".*_history .ssh .Xauthority .ICEauthority .xsession-errors* .wget-hsts .my.cnf .forward"
["r--"]=".*_logout .*rc .profile"
```

From 'privinfo.sh':

- priv_checklist: Used for validating **specific files in any part of the volume**, it compares the 'Others' permission bits against the target files'. 'Others' permission bits enclose with square brackets( [ ] ) and double apostrophes("), use only *absolute* file pathing. Can add multiple entries per permission combination.

```bash
Format:
["r-x"]="/etc/filename1 /var/log/file_name2 /file/name3"
["rwx"]="/filename4"

Default:
["---"]="/etc/shadow /etc/sudoers /etc/crontab"
["r--"]="/etc/passwd /etc/group /etc/profile /etc/fstab"
```

- folderlist: Same as 'priv_checklist' but for **folders** only.  

```bash
Format:
["r-x"]="/etc/folder1 /var/log/folder2 /file/folder3"
["rwx"]="/folder4"

Default:
["---"]="/etc/cron.d"
["r--"]="/var/log"
```

- sudoers_flags: These keywords/phrases will be looked out for in the '/etc/sudoers' file and its links, and will flag the entry for output if found. Multiple entries can be added, enclose with apostrophe(') and separate with spaces.

```bash
Format:
'NOPASSWD:' '(ALL : ALL)' 'your own string'

Default:
'NOPASSWD:'
```

From 'piscripts.sh':

- PASSWD_SRC: Contains the absolute path to a list of plaintext passwords to test on all users
- PKG_SRC: Contains the absolute path to a specially formatted list of package names, their configuration files and the related configurations to look out for

```bash
Format:
export PASSWD_SRC="/absolute/path/to/passwords.txt"
export PKG_SRC="/absolute/path/to/packages.txt"

Default:
export PASSWD_SRC="$script_dir/lists/passwords.txt"
export PKG_SRC="$script_dir/lists/packages.txt"
```

### The next set is are the plaintext wordlists in '**./lists**'

In the default '**passwords.txt**' file, a list of default plaintext passwords are provided.  
Each listed password is separated by a line break.

    raspberry
    dietpi
    pi
    root
    toor
    openelec
    libreelec
    osmc
    rootme
    ubuntu
    rokos
    dummy

In the default '**packages.txt**' file, a custom syntax is followed. Regular expression is supported here. Comments have a prefix of '#'.

    ### Contains list of packages to check for, all lines to check for are interpreted as REGEX, all HEADERS/CLOSURES ARE INTERPRETED IN SEQUENCE
    ### [PACKAGE_NAME]
    ### /ABSOLUTE/FILE/PATH.extension
    ###     <;;<OPTIONAL_START_FROM_THIS_STRING>;;>
    ###     EXACT_REGEX_STRING_TO_MATCH
    ###     EXACT_REGEX_STRING_TO_MATCH_2
    ###     <;;<OPTIONAL_END_WHEN_THIS_STRING>;;>

    [fail2ban]
    /etc/fail2ban/jail.local
        <;;<\[ssh\]>;;>
        enabled = true
        port = ssh
        bantime = ([1-9][0-9]{3,}|[7-9][0-9]{2}|6(0[1-9]|[1-9][0-9]))
        banaction = iptables-allports
        maxretry = ([1-9][0-9]+|[3-9])
        <;;<\[.+\]>;;>

    [unattended-upgrades]
    /etc/apt/apt.conf.d/50unattended-upgrades
        <;;<Unattended-Upgrade::Origins-Pattern {>;;>
            "o=\${distro_id},n=\${distro_codename},l=.+";
        <;;<};>;;>

    [ufw]
    /etc/default/ufw
        IPV6=yes
        DEFAULT_INPUT_POLICY="DROP"
    /etc/ufw/ufw.conf
        ENABLED=yes
    /etc/ufw/user.rules
        -A ufw-user-input -p tcp --dport 22 -j ACCEPT.+
    /etc/ufw/user6.rules

    [psad]
    /etc/psad/psad.conf

---
