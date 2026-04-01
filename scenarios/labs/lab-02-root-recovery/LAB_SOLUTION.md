# Lab 02: Root Password Recovery

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-02-root-recovery` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | boot-and-recovery |

Recover root access through the bootloader and restore normal access on clientvm.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Recover root access on clientvm from the console and…
**System:** clientvm

#### Command Flow
```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

### Task 02 - After the system boots normally, confirm that SELinux…
**System:** clientvm

#### Command Flow
```bash
getenforce
ls -Z /root | head
```

---

### Task 03 - Leave SSH password authentication working for root…
**System:** clientvm

#### Command Flow
```bash
vim /etc/ssh/sshd_config
PasswordAuthentication yes
PermitRootLogin yes
systemctl restart sshd
```

---

### Verification
```bash
getenforce
ls -Z /root | head
ssh -o StrictHostKeyChecking=no root@clientvm true
```
