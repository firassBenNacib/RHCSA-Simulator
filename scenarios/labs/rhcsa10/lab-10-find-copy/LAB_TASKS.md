# RHCSA 10 Lab 10: Find and Copy

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-10-find-copy` |
| Mode | Lab |
| Scope | client |
| Time limit | 20 minutes |
| Objectives | essential-tools |

Find files and preserve metadata.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /root/rhcsa10-found (client) - 10 pts

On client, create /root/rhcsa10-found.

---

## Task 02 - Copy every file smaller than 1 KiB from /etc/skel to /root/rhcsa10-found (client) - 10 pts

On client, copy every file smaller than 1 KiB from /etc/skel to /root/rhcsa10-found while preserving mode and timestamps.
