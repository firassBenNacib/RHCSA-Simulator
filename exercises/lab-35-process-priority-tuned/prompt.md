# Lab 35: Process Priority and Tuned

Time: 25 minutes
Objectives: processes-logs-tuning
Systems: clientvm

Tune the system with the requested profile and adjust process scheduling priority.

## Tasks

## Task 01 - Install the tuned package if it is not already (clientvm) - 10 pts

Install the tuned package if it is not already present and activate the tuned profile throughput-performance on clientvm.

## Task 02 - Start the command sleep 3600 in the background and (clientvm) - 10 pts

Start the command sleep 3600 in the background and save its PID in /root/sleep35.pid.

## Task 03 - Adjust the nice value of that process so it becomes 5 (clientvm) - 10 pts

Adjust the nice value of that process so it becomes 5.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
