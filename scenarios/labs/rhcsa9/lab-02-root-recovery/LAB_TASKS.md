# Lab 02: Root Password Recovery

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-02-root-recovery` |
| Mode | Lab |
| Scope | client |
| Time limit | 40 minutes |
| Objectives | boot-and-recovery |

Recover root access through the bootloader and restore normal access on client.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Recover root access on client from the console (client) - 10 pts

On client, recover root access from the console and set the root password to cinder9.

---

## Task 02 - After the system boots normally, confirm that (client) - 10 pts

On client, after the system boots normally, confirm that SELinux relabeling completed and root can log in again.

---

## Task 03 - Leave SSH password authentication working for root (client) - 10 pts

On client, leave SSH password authentication working for root and admin.
