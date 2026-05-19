# Lab 33: Bootloader Kernel Argument

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-33-grub-kernel-arg` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | boot-and-recovery |

Modify the system bootloader so every installed kernel boots with the required persistent argument.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure the persistent kernel argument (client) - 10 pts

Configure the bootloader on client so that every installed kernel boots persistently with the kernel argument audit_backlog_limit=8192 without manual GRUB editing during startup.
