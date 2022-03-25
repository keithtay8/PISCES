# PISCES - Pi Security Common Enhancements Suite

## Project Description

**PISCES ("Pi Security Common Enahncements Suite")** is a collection of security tools for the Raspberry Pi. It consists of three different privileged tools:

**RAT ("Raspbian Assessment Tool")** is a Raspberry Pi OS common scanner, with the goal of identifying common security misconfigurations within the Raspberry Pi OS. Some features include checking for default users/passwords, which default services are running on open ports, if display blanking is disabled properly and more!

**RABS ("Raspbian Automated Baseline Scanner")** is also a Raspberry Pi OS scanner, but with the goal of putting the Raspberry Pi OS against a benchmark instead. The CIS Ubuntu 20.04 benchmark is referenced here, and customized equivalents will be automatically executed. Each audit can be toggled and manually updated if neccessary.

**RAH ("Raspbian Automated Hardener")** is a fully-automated Raspberry Pi OS hardening script. It applies customized patches from the CIS Ubuntu 20.04 benchmark, aiming to bring the Pi up to a security standard. It is fully automated, only requiring the user to toggle their preferred patches at the beginning.

## Table of Contents

- [Raspbian Assessment Tool](#RAT)
- [Raspbian Automated Baseline Scanner](#RABS)
- [Raspbian Automated Hardener](#RAH)
