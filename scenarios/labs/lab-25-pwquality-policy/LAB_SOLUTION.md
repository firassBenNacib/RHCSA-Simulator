# Lab 25: Pwquality Policy - Lab Solution
Scenario ID: lab-25-pwquality-policy
Mode: Lab
Time limit: 20 minutes
Objectives: users-sudo-ssh

Configure a persistent local password quality policy without editing PAM service files.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
mkdir -p /etc/security/pwquality.conf.d
vim /etc/security/pwquality.conf.d/lab25.conf
minlen = 12
minclass = 3
```

## Task 02 - Part 02 (clientvm)
```bash
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
```

Verification
```bash
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
```
