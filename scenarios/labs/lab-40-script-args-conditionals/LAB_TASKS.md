# Lab 40: Script Arguments and Conditionals

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-40-script-args-conditionals` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | shell-scripting, users-sudo-ssh |

Create a small shell script that processes arguments and returns the correct exit status.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the executable script (client) - 10 pts

Create the executable script /usr/local/bin/usercheck40 on client.

---

## Task 02 - The script must accept one username argument (client) - 10 pts

The script must accept one username argument.

---

## Task 03 - If the user exists, print EXISTS: username to (client) - 10 pts

If the user exists, print EXISTS: username to standard output and exit with status 0.

---

## Task 04 - If the user does not exist, print MISSING: username (client) - 10 pts

If the user does not exist, print MISSING: username to standard output and exit with status 1.
