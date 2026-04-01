# Lab 02: Root Password Recovery

## Lab Tasks
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

Recover root access on clientvm from the console and set the root password to cinder9.

---

### Task 02 - After the system boots normally, confirm that SELinux…
**System:** clientvm

After the system boots normally, confirm that SELinux relabeling completed and root can log in again.

---

### Task 03 - Leave SSH password authentication working for root…
**System:** clientvm

Leave SSH password authentication working for root and admin.

### Hints
- Use the boot menu edit path with rw init=/bin/bash.
- Remember to touch /.autorelabel before starting the normal init process.

### Validation Commands
```bash
getenforce
ls -Z /root | head
ssh -o StrictHostKeyChecking=no root@clientvm true
```
