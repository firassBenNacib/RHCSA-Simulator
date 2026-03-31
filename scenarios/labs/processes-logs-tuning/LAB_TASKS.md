# Processes, Logs, Targets, And Tuning - Lab Tasks
Scenario ID: processes-logs-tuning
Mode: Lab
Time limit: 60 minutes
Objectives: processes-logs-tuning

Practice RHCSA v9 process control, persistent logging, systemd targets, and performance tuning.

## Task 01 - Busy Process Priority (clientvm) - 10 pts
Identify the CPU-intensive process started by the scenario and lower its CPU priority without stopping it.

## Task 02 - Persistent Journal (clientvm) - 10 pts
Configure the system to preserve the journal across reboots.

## Task 03 - Throughput Performance Profile (clientvm) - 10 pts
Set the tuned profile to throughput-performance and confirm it is active.

## Task 04 - Note Service (clientvm) - 10 pts
Enable and start the rhcsa-note.service unit that writes a stamp file under /var/tmp.

## Task 05 - Default Boot Target (clientvm) - 10 pts
Change the default boot target to multi-user.target.

Hints
1. Use ps, top, renice, or systemctl as needed.
2. Persistent journaling requires a writable journal directory and journald configuration that keeps logs.
3. tuned-adm is the expected interface for the tuning task.

Checks
```bash
ps -eo pid,ni,comm --sort=ni | head
grep -n '^Storage=' /etc/systemd/journald.conf
tuned-adm active
systemctl status rhcsa-note.service --no-pager
systemctl get-default
```
