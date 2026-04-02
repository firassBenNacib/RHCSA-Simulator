# Lab 23: Umask Defaults

Time: 25 minutes
Objectives: selinux-and-default-perms, users-sudo-ssh
Systems: clientvm

Configure a user specific umask so new files and directories get the required default permissions.

## Tasks

## Task 01 - Create the user veil23 and set its password to cinder9 (clientvm) - 10 pts

Create the user veil23 and set its password to cinder9.

## Task 02 - Configure the umask for user veil23 so that new (clientvm) - 10 pts

Configure the umask for user veil23 so that new regular files are created with mode 0640 and new directories are created with mode 0750 whenever the user logs in.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
