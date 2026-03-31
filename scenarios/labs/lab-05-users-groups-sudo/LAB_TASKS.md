# Lab 05: Users Groups And Sudo - Lab Tasks
Scenario ID: lab-05-users-groups-sudo
Mode: Lab
Time limit: 40 minutes
Objectives: users-sudo-ssh

Create local users, a delegated admin group, and passwordless privileged access.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create the group sysadmx and the users harryx, natashax, and sarahx. Put harryx and natashax in sysadmx as a supplementary group. Sarahx must have /sbin/nologin and must not be in sysadmx.

## Task 02 - Part 02 (clientvm)
Set the password of all three users to redhat.

## Task 03 - Part 03 (clientvm)
Allow members of sysadmx to run useradd through sudo, and allow harryx to run passwd for other users without a sudo password prompt.

Hints
1. Use useradd and usermod only.
2. Create sudo policy files under /etc/sudoers.d and validate them with visudo.

Checks
```bash
id harryx
id natashax
getent passwd sarahx
visudo -cf /etc/sudoers.d/sysadmx
visudo -cf /etc/sudoers.d/harryx-passwd
```
