# Lab 26: Default ACL Shared Directory

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-26-default-acl-shared-dir` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | filesystems-and-autofs, selinux-and-default-perms |

Use a default ACL for a named user without creating an unnecessary home directory.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the collab26 group and probe26 user (clientvm) - 10 pts

Create the group collab26 and the user probe26 without a home directory. Set the password of probe26 to cinder9.

---

## Task 02 - Create the shared directory with setgid semantics (clientvm) - 10 pts

Create the directory /shared/collab26 with owner root, group collab26, and permissions 2770.

---

## Task 03 - Create the default ACL for probe26 (clientvm) - 10 pts

Configure a default ACL so that user probe26 receives rwx permissions on new files and directories created under /shared/collab26.
