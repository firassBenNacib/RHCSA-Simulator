# RHCSA 10 Lab 43: Sticky Directory

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-43-sticky-directory` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Configure shared directory permissions.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - create group share10 (server) - 10 pts

```bash
groupadd share10
```

---

## Task 02 - create /srv/share10 owned by root:share10 (server) - 10 pts

```bash
mkdir -p /srv/share10
chown root:share10 /srv/share10
```

---

## Task 03 - set permissions so group members can write and only owners can delete th (server) - 10 pts

```bash
chmod 3770 /srv/share10
```
