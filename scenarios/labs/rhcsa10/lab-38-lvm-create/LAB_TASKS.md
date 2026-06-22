# RHCSA 10 Lab 38: LVM Create

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-38-lvm-create` |
| Mode | Lab |
| Scope | client |
| Time limit | 40 minutes |
| Objectives | storage-lvm |

Create and mount a logical volume.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create physical volume /dev/sdb (client) - 10 pts

On client, create physical volume /dev/sdb.

---

## Task 02 - Create volume group (client) - 10 pts

On client, create volume group vg10.

---

## Task 03 - Configure LVM storage (client) - 10 pts

On client, using volume group vg10 on /dev/sdb, create a 384 MiB logical volume lvdata, format it with XFS, and mount it persistently at /mnt/lvdata10.
