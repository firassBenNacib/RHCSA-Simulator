# Lab 06: Shared Setgid Directory

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-06-shared-setgid-directory` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | filesystems-and-autofs, selinux-and-default-perms |

Build a collaborative directory that uses both setgid and sticky semantics.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the shared analysts directory (client) - 10 pts

On client, create the group analystsx and the directory /shared/analysts with owner root, group analystsx, and access limited to root and members of analystsx.

---

## Task 02 - Enable setgid and sticky behavior on the directory (client) - 10 pts

On client, configure /shared/analysts so new files inherit the analystsx group and only the file owner, the directory owner, or root can remove entries from it.
