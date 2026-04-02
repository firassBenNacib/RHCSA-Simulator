# Lab 05: Users Groups And Sudo

Time: 40 minutes
Objectives: users-sudo-ssh
Systems: clientvm

Create local users, a delegated admin group, and passwordless privileged access.

## Tasks

## Task 01 - Create the group opsrune and the users brenor, (clientvm) - 10 pts

Create the group opsrune and the users brenor, lyessa, and quillan. Put brenor and lyessa in opsrune as a supplementary group. Sarahx must have /sbin/nologin and must not be in opsrune.

## Task 02 - Set the password of all three users to cinder9 (clientvm) - 10 pts

Set the password of all three users to cinder9.

## Task 03 - Allow members of opsrune to run useradd through (clientvm) - 10 pts

Allow members of opsrune to run useradd through sudo, and allow brenor to run passwd for other users without a sudo password prompt.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
