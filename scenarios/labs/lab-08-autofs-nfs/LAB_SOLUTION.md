# Lab 08: Autofs With NFS

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-08-autofs-nfs` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | filesystems-and-autofs |

Configure an indirect automount from servervm.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Seed Export And User (clientvm + servervm) - 10 pts

```bash
# On servervm
mkdir -p /exports/vault8
echo 'autofs lab 08' > /exports/vault8/welcome.txt
exportfs -arv
# On clientvm
useradd vault8
passwd vault8
# enter: cinder9
```

---

## Task 02 - Configure Autofs Map (clientvm) - 10 pts

```bash
vim /etc/auto.lab8
vault8 -rw,sync servervm:/exports/vault8
vim /etc/auto.master.d/lab8.autofs
/netdir /etc/auto.lab8
systemctl enable --now autofs
for attempt in 1 2 3 4 5; do ls /netdir/vault8 >/dev/null 2>&1 && mount | grep -Eq 'servervm:/exports/vault8 on /netdir/vault8 type nfs' && break; sleep 2; done
mount | grep -Eq 'servervm:/exports/vault8 on /netdir/vault8 type nfs'
```

---

## Task 03 - Verify Access (clientvm) - 10 pts

```bash
ls -l /netdir/vault8
cat /netdir/vault8/welcome.txt
```
