# Lab 16: Additional Swap Space

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-16-swap-space` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | storage-lvm |

Add a persistent swap partition on an extra disk.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create a 400 MiB swap partition on /dev/sdb, enable…
**System:** clientvm

Create a 400 MiB swap partition on /dev/sdb, enable it, and make it persistent.

### Hints
- Use GPT partition type 19 for swap.
- Use a UUID entry in /etc/fstab.

### Validation Commands
```bash
swapon --show
lsblk -f /dev/sdb
```
