# RHCSA 10 Lab 34: Kernel Argument

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-34-grub-argument` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | boot-and-recovery |

Persistently modify bootloader kernel arguments.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Add kernel argument audit_backlog_limit=8192 persistently (client) - 10 pts

Add kernel argument audit_backlog_limit=8192 persistently.

---

## Task 02 - Regenerate the GRUB configuration (client) - 10 pts

Regenerate the GRUB configuration.

---

## Task 03 - Verify the argument is present in /etc/default/grub or grubby output (client) - 10 pts

Verify the argument is present in /etc/default/grub or grubby output.
