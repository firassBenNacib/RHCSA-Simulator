# Lab 44: Filesystem By Label

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-44-filesystem-label-mount` |
| Mode | Lab |
| Scope | client |
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

```bash
umount /data44 >/dev/null 2>&1 || true
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdb bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
printf 'label: gpt\n,600MiB,L\n' | sfdisk --wipe always /dev/sdb
partprobe /dev/sdb || true
partx -u /dev/sdb || partx -a /dev/sdb || true
udevadm settle
for attempt in 1 2 3 4 5 6 7 8 9 10; do test -b /dev/sdb1 && break; partprobe /dev/sdb || true; partx -u /dev/sdb || true; udevadm settle; sleep 1; done
test -b /dev/sdb1
```

---

## Task 02 - Format and mount the filesystem by label (client) - 10 pts

```bash
mkfs.ext4 -L DATA44 /dev/sdb1
mkdir -p /data44
mount LABEL=DATA44 /data44
```

---

## Task 03 - Persist the LABEL mount in fstab (client) - 10 pts

```bash
vim /etc/fstab
LABEL=DATA44 /data44 ext4 defaults 0 0
```
