# Lab 26: Default ACL Shared Directory

Time: 30 minutes
Objectives: filesystems-and-autofs, selinux-and-default-perms
Systems: clientvm

Create a collaborative directory that combines setgid permissions with a default ACL.

## Tasks

## Task 01 - Create the group collab26 and the user probe26. Set (clientvm) - 10 pts

Create the group collab26 and the user probe26. Set the password of probe26 to cinder9.

## Task 02 - Create the directory /shared/collab26 with owner (clientvm) - 10 pts

Create the directory /shared/collab26 with owner root, group collab26, and permissions 2770.

## Task 03 - Configure a default ACL so that user probe26 (clientvm) - 10 pts

Configure a default ACL so that user probe26 receives rwx permissions on new files and directories created under /shared/collab26.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
