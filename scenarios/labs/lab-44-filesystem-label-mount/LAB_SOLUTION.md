# Lab 44: Filesystem By Label

## Lab Solution
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

```bash
printf 'label: gpt
,600MiB,L
' | sfdisk /dev/sdb
partprobe /dev/sdb
```

---

## Task 02 - Format and mount the filesystem by label (clientvm) - 10 pts

```bash
mkfs.ext4 -L DATA44 /dev/sdb1
mkdir -p /data44
mount LABEL=DATA44 /data44
```

---

## Task 03 - Persist the LABEL mount in fstab (clientvm) - 10 pts

```bash
printf 'LABEL=DATA44 /data44 ext4 defaults 0 0
' >> /etc/fstab
```

---

## Verification
```bash
blkid -o value -s LABEL /dev/sdb1 | grep -qx DATA44
findmnt -n /data44 | grep -Fq '/data44'
grep -Eq '^LABEL=DATA44[[:space:]]+/data44[[:space:]]+ext4[[:space:]]+defaults[[:space:]]+0[[:space:]]+0$' /etc/fstab
```
