# Lab 23: Umask Defaults

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-23-umask-defaults` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms, users-sudo-ssh |

Configure a user specific umask so new files and directories get the required default permissions.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the user veil23 and set its password to cinder9 (clientvm) - 10 pts

Create the user veil23 and set its password to cinder9.

---

## Task 02 - Configure the umask for user veil23 so that new (clientvm) - 10 pts

Configure the umask for user veil23 so that new regular files are created with mode 0640 and new directories are created with mode 0750 whenever the user logs in.
