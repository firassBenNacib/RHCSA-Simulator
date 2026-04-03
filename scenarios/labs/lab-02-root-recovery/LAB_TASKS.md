# Lab 02: Root Password Recovery

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-02-root-recovery` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | boot-and-recovery |

Recover root access through the bootloader and restore normal access on clientvm.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Recover root access on clientvm from the console (clientvm) - 10 pts

Recover root access on clientvm from the console and set the root password to cinder9.

---

## Task 02 - After the system boots normally, confirm that (clientvm) - 10 pts

After the system boots normally, confirm that SELinux relabeling completed and root can log in again.

---

## Task 03 - Leave SSH password authentication working for root (clientvm) - 10 pts

Leave SSH password authentication working for root and admin.
