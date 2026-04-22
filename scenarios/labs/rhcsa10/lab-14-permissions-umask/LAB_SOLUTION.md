# RHCSA 10 Lab 14: Permissions And Umask

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-14-permissions-umask` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Manage default permissions.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set root's shell umask to 027 using /root/.bashrc (client) - 10 pts

```bash
grep -qx 'umask 027' /root/.bashrc || echo 'umask 027' >> /root/.bashrc
```

---

## Task 02 - Create /srv/rhcsa10-private with owner root and group root (client) - 10 pts

```bash
mkdir -p /srv/rhcsa10-private
chown root:root /srv/rhcsa10-private
```

---

## Task 03 - Set directory permissions to 750 (client) - 10 pts

```bash
chmod 750 /srv/rhcsa10-private
```
