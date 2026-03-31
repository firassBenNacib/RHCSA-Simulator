# Lab 24: Password Aging Defaults - Lab Solution
Scenario ID: lab-24-password-aging-defaults
Mode: Lab
Time limit: 30 minutes
Objectives: users-sudo-ssh

Configure default password aging for newly created local users through login.defs.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
vim /etc/login.defs
PASS_MAX_DAYS   45
PASS_MIN_DAYS   2
PASS_WARN_AGE   10
```

## Task 02 - Part 02 (clientvm)
```bash
useradd -m aging24
passwd aging24
# enter: redhat
chage -l aging24
```

Verification
```bash
grep -E '^PASS_(MAX_DAYS|MIN_DAYS|WARN_AGE)' /etc/login.defs
chage -l aging24
```
