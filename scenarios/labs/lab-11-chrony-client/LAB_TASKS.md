# Lab 11: Time Synchronization - Lab Tasks
Scenario ID: lab-11-chrony-client
Mode: Lab
Time limit: 20 minutes
Objectives: software-scheduling-time

Configure clientvm to synchronize time from servervm.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

Hints
1. Remove any other server or pool lines.
2. Use iburst on the server line.

Checks
```bash
chronyc sources -v
systemctl status chronyd --no-pager
```
