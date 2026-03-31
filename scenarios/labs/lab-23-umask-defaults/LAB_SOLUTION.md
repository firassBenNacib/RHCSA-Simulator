# Lab 23: Umask Defaults - Lab Solution
Scenario ID: lab-23-umask-defaults
Mode: Lab
Time limit: 25 minutes
Objectives: selinux-and-default-perms, users-sudo-ssh

Configure a user specific umask so new files and directories get the required default permissions.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
useradd -m umask23
passwd umask23
# enter: redhat
```

## Task 02 - Part 02 (clientvm)
```bash
vim /home/umask23/.bashrc
umask 027
chown umask23:umask23 /home/umask23/.bashrc
```

Verification
```bash
id umask23
runuser -l umask23 -c 'rm -rf ~/umask23-check && mkdir ~/umask23-check && touch ~/umask23-check/file && mkdir ~/umask23-check/dir && stat -c %a ~/umask23-check/file ~/umask23-check/dir'
```
