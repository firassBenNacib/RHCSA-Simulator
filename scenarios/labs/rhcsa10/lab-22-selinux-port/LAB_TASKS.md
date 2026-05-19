# RHCSA 10 Lab 22: SELinux HTTP Port

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-22-selinux-port` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms, networking-and-firewall |

Manage SELinux port labels.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Add TCP port 8010 as an http_port_t SELinux port (client) - 10 pts

Add TCP port 8010 as an http_port_t SELinux port.

---

## Task 02 - Configure firewalld to allow TCP port 8010 permanently (client) - 20 pts

Configure firewalld to allow TCP port 8010 permanently.
