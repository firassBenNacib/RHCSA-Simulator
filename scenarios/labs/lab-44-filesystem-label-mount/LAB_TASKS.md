# Lab 44: Filesystem By Label

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-44-filesystem-label-mount` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | storage-lvm |

Create a filesystem, label it, and mount it persistently by label.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - On /dev/sdb, create a GPT partition of 600 MiB for an…
**System:** clientvm

On /dev/sdb, create a GPT partition of 600 MiB for an ext4 filesystem.

---

### Task 02 - Format the new partition with the filesystem label…
**System:** clientvm

Format the new partition with the filesystem label DATA44 and mount it at /data44.

---

### Task 03 - Configure the mount persistently in /etc/fstab by…
**System:** clientvm

Configure the mount persistently in /etc/fstab by using LABEL=DATA44.

### Hints
- Use blkid or lsblk -f to verify the label.

### Validation Commands
```bash
blkid /dev/sdb1
findmnt /data44
```
