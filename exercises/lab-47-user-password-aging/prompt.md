# Lab 47: Per-User Password Aging

Time: 25 minutes
Objectives: users-sudo-ssh
Systems: clientvm

Adjust password aging for an existing user account with chage.

## Tasks

## Task 01 - Create user cycle47 with password cinder9 if it (clientvm) - 10 pts

Create user cycle47 with password cinder9 if it does not already exist.

## Task 02 - Configure cycle47 with a maximum password age of 30 (clientvm) - 10 pts

Configure cycle47 with a maximum password age of 30 days, a minimum age of 2 days, and a warning period of 7 days.

## Task 03 - Force cycle47 to change the password at the next login (clientvm) - 10 pts

Force cycle47 to change the password at the next login.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
