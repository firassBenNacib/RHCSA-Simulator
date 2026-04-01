# Lab 08: Autofs With NFS

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-08-autofs-nfs` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | filesystems-and-autofs |

Configure an indirect automount from servervm.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Seed Export And User
**System:** clientvm + servervm

#### Command Flow
```bash
# On servervm
mkdir -p /exports/vault8
printf "autofs lab 08\n" > /exports/vault8/welcome.txt
exportfs -arv
# On clientvm
useradd -m vault8
passwd vault8
# enter: cinder9
```

---

### Task 02 - Configure Autofs Map
**System:** clientvm

#### Command Flow
```bash
vim /etc/auto.lab8
vault8 -rw,sync servervm:/exports/vault8
vim /etc/auto.master.d/lab8.autofs
/netdir /etc/auto.lab8
systemctl enable --now autofs
```

---

### Task 03 - Verify Access
**System:** clientvm

#### Command Flow
```bash
ls -l /netdir/vault8
cat /netdir/vault8/welcome.txt
```

---

### Verification
```bash
showmount -e servervm
ls -l /netdir/vault8
ls -l /netdir/vault8/welcome.txt
```
