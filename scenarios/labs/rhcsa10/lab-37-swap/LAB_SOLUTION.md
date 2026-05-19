# RHCSA 10 Lab 37: Swap Space

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-37-swap` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | storage-lvm |

Add persistent swap space.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create a 512 MiB swap partition on /dev/sdb (client) - 10 pts

```bash
parted -s /dev/sdb mklabel gpt mkpart primary linux-swap 1MiB 513MiB
mkswap /dev/sdb1
```

---

## Task 02 - Enable the swap immediately (client) - 10 pts

```bash
swapon /dev/sdb1
```

---

## Task 03 - Make the swap persistent across reboots (client) - 10 pts

```bash
echo '/dev/sdb1 swap swap defaults 0 0' >> /etc/fstab
```
