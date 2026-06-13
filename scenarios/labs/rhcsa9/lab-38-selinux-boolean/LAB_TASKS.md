# Lab 38: SELinux Boolean

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-38-selinux-boolean` |
| Mode | Lab |
| Scope | client |
| Time limit | 15 minutes |
| Objectives | selinux-and-default-perms |

Modify a SELinux boolean persistently without changing enforcing mode.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Enable the SELinux boolean while keeping enforcing mode (client) - 20 pts

On client, configure the SELinux boolean httpd_can_network_connect so it is enabled persistently while SELinux remains in enforcing mode.
