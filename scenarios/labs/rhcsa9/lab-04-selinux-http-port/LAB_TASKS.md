# Lab 04: SELinux Custom HTTP Port

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-04-selinux-http-port` |
| Mode | Lab |
| Scope | server |
| Time limit | 35 minutes |
| Objectives | selinux-and-default-perms |

Fix Apache so it listens on a nonstandard port without disabling SELinux.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure Apache on server so it listens on TCP (server) - 10 pts

On server, configure Apache so it listens on TCP port 9082 and starts automatically at boot.

---

## Task 02 - Allow TCP port 9082 through the firewall permanently (server) - 10 pts

On server, allow TCP port 9082 through the firewall permanently.

---

## Task 03 - Make the SELinux changes needed so Apache serves (server) - 10 pts

On server, make the SELinux changes needed so Apache serves the existing /var/www/html content on that port.
