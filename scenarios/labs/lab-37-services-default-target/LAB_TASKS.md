# Lab 37: Services and Default Target

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-37-services-default-target` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, boot-and-recovery |

Manage the default target and key services on servervm.

### Systems
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set the default boot target on servervm (servervm) - 10 pts

Configure servervm to boot into multi-user.target by default.

---

## Task 02 - Enable rsyslog on servervm (servervm) - 10 pts

Ensure the rsyslog service is enabled and running on servervm.

---

## Task 03 - Disable postfix on servervm if present (servervm) - 10 pts

If postfix is installed on servervm, disable it and stop it.
