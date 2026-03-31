# Lab 44: Filesystem By Label

## Lab Solution
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

### Task 01 — On /dev/sdb, create a GPT partition of 600 MiB for an…
**System:** clientvm

#### Command Flow
```bash
fdisk /dev/sdb
# g
# n
# <Enter>
# <Enter>
# +600M
# w
```

---

### Task 02 — Format the new partition with the filesystem label…
**System:** clientvm

#### Command Flow
```bash
mkfs.ext4 -L DATA44 /dev/sdb1
mkdir -p /data44
```

---

### Task 03 — Configure the mount persistently in /etc/fstab by…
**System:** clientvm

#### Command Flow
```bash
vim /etc/fstab
LABEL=DATA44 /data44 ext4 defaults 0 0
:wq
mount -a
findmnt /data44
```

---

### Verification
```bash
blkid /dev/sdb1
findmnt /data44
```
