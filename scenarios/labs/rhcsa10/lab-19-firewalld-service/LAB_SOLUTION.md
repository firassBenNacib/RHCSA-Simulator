# RHCSA 10 Lab 19: Firewalld Service

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-19-firewalld-service` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | networking-and-firewall, selinux-and-default-perms |

Manage persistent firewalld service rules.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - ensure firewalld is enabled and running (server) - 10 pts

```bash
systemctl enable --now firewalld
```

---

## Task 02 - permanently allow the https service in the public zone (server) - 10 pts

```bash
firewall-cmd --permanent --zone=public --add-service=https
```

---

## Task 03 - reload firewalld and verify the service is allowed (server) - 10 pts

```bash
firewall-cmd --reload
firewall-cmd --zone=public --list-services
```
