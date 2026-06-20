# RHCSA 10 Lab 34: Kernel Argument

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-34-grub-argument` |
| Mode | Lab |
| Scope | client |
| Time limit | 20 minutes |
| Objectives | boot-and-recovery |

Persistently modify bootloader kernel arguments.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Add kernel argument audit_backlog_limit=8192 persistently and regenerate (client) - 10 pts

On client, add kernel argument audit_backlog_limit=8192 persistently and regenerate the GRUB configuration.
