# Lab 14: User With Fixed UID - Lab Tasks
Scenario ID: lab-14-user-fixed-uid
Mode: Lab
Time limit: 15 minutes
Objectives: users-sudo-ssh

Create a local user with a specific UID.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create user choubix with UID 4111 and set its password to redhat.

Hints
1. Use passwd interactively.

Checks
```bash
id choubix
```
