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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the 600 MiB partition on /dev/sdb (clientvm) - 10 pts

On /dev/sdb, create a GPT partition of 600 MiB for an ext4 filesystem.

---

## Task 02 - Format and mount the filesystem by label (clientvm) - 10 pts

Format the new partition with the filesystem label DATA44 and mount it at /data44.

---

## Task 03 - Persist the LABEL mount in fstab (clientvm) - 10 pts

Configure the mount persistently in /etc/fstab by using LABEL=DATA44.

## Hints
- The title already tells you the required persistence method.
- Use LABEL=DATA44, not a device path or UUID.

## Validation Commands
```bash
blkid -o value -s LABEL /dev/sdb1 | grep -qx DATA44
findmnt -n /data44 | grep -Fq '/data44'
grep -Eq '^LABEL=DATA44[[:space:]]+/data44[[:space:]]+ext4[[:space:]]+defaults[[:space:]]+0[[:space:]]+0$' /etc/fstab
```
