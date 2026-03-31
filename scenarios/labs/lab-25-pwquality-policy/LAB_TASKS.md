# Lab 25: Pwquality Policy - Lab Tasks
Scenario ID: lab-25-pwquality-policy
Mode: Lab
Time limit: 20 minutes
Objectives: users-sudo-ssh

Configure a persistent local password quality policy without editing PAM service files.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create a persistent password quality policy in /etc/security/pwquality.conf.d so that local passwords must meet the following requirements:

MINIMUM LENGTH: 12
MINIMUM CHARACTER CLASSES: 3

## Task 02 - Part 02 (clientvm)
Do not edit any PAM service file for this task.

Hints
1. Use a dedicated drop-in file.
2. Keep the configuration minimal.

Checks
```bash
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
```
