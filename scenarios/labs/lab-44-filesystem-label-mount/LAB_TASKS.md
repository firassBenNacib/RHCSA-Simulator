# Lab 44: Filesystem By Label

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-44-filesystem-label-mount` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | storage-lvm |

Create an ext4 filesystem by label and mount it persistently.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the 600 MiB partition on /dev/sdb (client) - 10 pts

On /dev/sdb, create a GPT partition of 600 MiB for an ext4 filesystem.

---

## Task 02 - Format and mount the filesystem by label (client) - 10 pts

Format the new partition with the filesystem label DATA44 and mount it at /data44.

---

## Task 03 - Persist the LABEL mount in fstab (client) - 10 pts

Configure the mount persistently in /etc/fstab by using LABEL=DATA44.
