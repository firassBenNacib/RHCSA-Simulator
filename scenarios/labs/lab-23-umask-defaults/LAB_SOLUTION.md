# Lab 23: Umask Defaults

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-23-umask-defaults` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms, users-sudo-ssh |

Configure a user specific umask so new files and directories get the required default permissions.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the user veil23 and set its password to cinder9 (clientvm) - 10 pts

```bash
useradd -m veil23
passwd veil23
# enter: cinder9
```

---

## Task 02 - Configure the umask for user veil23 so that new (clientvm) - 10 pts

```bash
vim /home/veil23/.bashrc
umask 027
chown veil23:veil23 /home/veil23/.bashrc
```
