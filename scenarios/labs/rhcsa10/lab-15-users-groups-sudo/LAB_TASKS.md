# RHCSA 10 Lab 15: Users Groups and Sudo

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-15-users-groups-sudo` |
| Mode | Lab |
| Scope | client |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Create local identities and delegate limited administrative access.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create local group ops10 (client) - 10 pts

Create local group ops10.

---

## Task 02 - Create user relay10, set the password to cinder9, and make ops10 (client) - 10 pts

Create user relay10, set the password to cinder9, and make ops10 the user's supplementary group.

---

## Task 03 - Configure sudo access (client) - 10 pts

Allow members of ops10 to run /usr/bin/systemctl with sudo without a password.
