# RHCSA 10 Lab 35: Root Recovery

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-35-root-recovery` |
| Mode | Lab |
| Scope | client |
| Time limit | 20 minutes |
| Objectives | boot-and-recovery |

Practice the root password recovery workflow.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - from the console, interrupt boot and enter emergency recovery mode (client) - 10 pts

```bash
# console task: interrupt GRUB and boot with rd.break
```

---

## Task 02 - Set the root password to cinder9 (client) - 10 pts

```bash
passwd root
# enter: cinder9
```

---

## Task 03 - Relabel the system if SELinux requires it (client) - 10 pts

```bash
touch /.autorelabel
reboot
```
