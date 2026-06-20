# RHCSA 10 Lab 39: LVM Extend

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-lvm-extend` |
| Mode | Lab |
| Scope | client |
| Time limit | 30 minutes |
| Objectives | storage-lvm |

Extend an existing logical volume and filesystem.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create volume group (client) - 10 pts

On client, create volume group grow10 on /dev/sdb.

---

## Task 02 - Configure LVM storage (client) - 10 pts

On client, create logical volume growlv with size 384 MiB and XFS filesystem mounted at /mnt/grow10.

---

## Task 03 - Configure LVM storage (client) - 10 pts

On client, extend the logical volume and filesystem to at least 512 MiB.
