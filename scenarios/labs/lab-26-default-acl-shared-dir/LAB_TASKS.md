# Lab 26: Default ACL Shared Directory - Lab Tasks
Scenario ID: lab-26-default-acl-shared-dir
Mode: Lab
Time limit: 30 minutes
Objectives: filesystems-and-autofs, selinux-and-default-perms

Create a collaborative directory that combines setgid permissions with a default ACL.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create the group collab26 and the user qa26. Set the password of qa26 to redhat.

## Task 02 - Part 02 (clientvm)
Create the directory /shared/collab26 with owner root, group collab26, and permissions 2770.

## Task 03 - Part 03 (clientvm)
Configure a default ACL so that user qa26 receives rwx permissions on new files and directories created under /shared/collab26.

Hints
1. Use getfacl to confirm the effective and default entries.

Checks
```bash
getfacl /shared/collab26
```
