# Lab 05: Users Groups And Sudo

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-05-users-groups-sudo` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | users-sudo-ssh |

Create local users on servervm with minimal useradd usage and delegated sudo rules.

### Systems
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create opsrune and the required users (servervm) - 10 pts

Create the group opsrune and the users brenor, lyessa, and quillan. Create brenor and lyessa with opsrune as a supplementary group at creation time. Create sarahx without a home directory and with the shell /sbin/nologin.

---

## Task 02 - Set the interactive user passwords to cinder9 (servervm) - 10 pts

Set the passwords of brenor, lyessa, and quillan to cinder9.

---

## Task 03 - Create the required sudo rules (servervm) - 10 pts

Allow members of opsrune to run /usr/sbin/useradd through sudo, and allow brenor to run /usr/bin/passwd for other users without a sudo password prompt.
