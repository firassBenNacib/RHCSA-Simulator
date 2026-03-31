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

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
# At the boot menu, edit the selected entry and append rd.break to the linux line.
# Boot with Ctrl+x.
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
# enter: redhat
touch /.autorelabel
exit
exit
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
getenforce
ls -Z /root | head
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
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
