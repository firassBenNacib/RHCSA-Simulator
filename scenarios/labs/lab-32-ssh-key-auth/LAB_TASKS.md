# Lab 32: SSH Key Authentication

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-32-ssh-key-auth` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | users-sudo-ssh |

Configure passwordless SSH login from clientvm to servervm using a key pair.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user relay32 on clientvm and user vault32 on (clientvm + servervm) - 10 pts

Create user relay32 on clientvm and user vault32 on servervm. Set the password of both users to cinder9.

---

## Task 02 - Configure key-based SSH authentication so that user (clientvm) - 10 pts

Configure key-based SSH authentication so that user relay32 on clientvm can log in to vault32@servervm without a password prompt.

---

## Task 03 - Do not disable PasswordAuthentication globally for (clientvm) - 10 pts

Do not disable PasswordAuthentication globally for this task.
