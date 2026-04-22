# Lab 25: Pwquality Policy

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-25-pwquality-policy` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | users-sudo-ssh |

Use a pwquality drop-in to enforce a stronger local password policy.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the pwquality drop-in without editing PAM (client) - 30 pts

Create a persistent password quality policy in /etc/security/pwquality.conf.d so that local passwords require a minimum length of 12, at least 3 character classes, and no more than 2 repeated characters in sequence. Do not edit any PAM service file for this task.
