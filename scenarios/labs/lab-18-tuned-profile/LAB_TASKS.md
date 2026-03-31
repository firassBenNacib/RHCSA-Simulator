# Lab 18: Tuned Recommended Profile - Lab Tasks
Scenario ID: lab-18-tuned-profile
Mode: Lab
Time limit: 15 minutes
Objectives: processes-logs-tuning

Apply the system recommended tuned profile.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Apply the recommended tuned profile and leave it active after reboot.

Hints
1. Use tuned-adm recommended to see the target profile.

Checks
```bash
tuned-adm active
tuned-adm recommended
```
