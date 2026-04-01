# Lab 36: Persistent NFS Direct Mount

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-36-nfs-direct-mount` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | nfs-and-autofs, storage-lvm |

Mount a remote NFS export persistently using /etc/fstab.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Persistently mount the NFS export…
**System:** clientvm

#### Command Flow
```bash
mkdir -p /mnt/direct36
vim /etc/fstab
192.168.122.3:/exports/direct36 /mnt/direct36 nfs ro,sync 0 0
:wq
```

---

### Task 02 - Use the mount options ro,sync
**System:** clientvm

#### Command Flow
```bash
mount -a
```

---

### Task 03 - Ensure the mount is available after a reboot and that…
**System:** clientvm

#### Command Flow
```bash
ls /mnt/direct36
```

---

### Verification
```bash
grep -q "/mnt/direct36" /etc/fstab
mountpoint -q /mnt/direct36
test -f /mnt/direct36/nfs36.txt
```
