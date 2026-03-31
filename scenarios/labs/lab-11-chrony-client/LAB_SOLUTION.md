# Lab 11: Time Synchronization - Lab Solution
Scenario ID: lab-11-chrony-client
Mode: Lab
Time limit: 20 minutes
Objectives: software-scheduling-time

Configure clientvm to synchronize time from servervm.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
vim /etc/chrony.conf
server servervm iburst
# remove any other server or pool lines
systemctl enable --now chronyd
chronyc sources -v
```

Verification
```bash
chronyc sources -v
systemctl status chronyd --no-pager
```
