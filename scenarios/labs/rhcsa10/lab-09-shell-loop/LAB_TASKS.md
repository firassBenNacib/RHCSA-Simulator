# RHCSA 10 Lab 09: Loop Script

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-09-shell-loop` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | shell-scripting |

Create a shell script that loops over input.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user lookup script (client) - 10 pts

On client, create /usr/local/bin/rhcsa10-lines.

---

## Task 02 - Make the script executable, read /etc/passwd, and overwrite (client) - 10 pts

On client, make the script executable, read /etc/passwd, and overwrite /root/rhcsa10-lines.txt with every account name that starts with r.
