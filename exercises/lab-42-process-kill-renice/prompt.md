# Lab 42: Process Kill And Renice

Time: 25 minutes
Objectives: processes-logs-tuning
Systems: clientvm

Identify a running process, terminate it, and adjust the scheduling priority of another one.

## Tasks

## Task 01 - user worker42 has a CPU-bound process whose PID is (clientvm) - 10 pts

On clientvm, user worker42 has a CPU-bound process whose PID is stored in /home/worker42/cpu.pid. Terminate that process.

## Task 02 - User worker42 also has a long-running sleep process (clientvm) - 10 pts

User worker42 also has a long-running sleep process whose PID is stored in /home/worker42/sleep.pid. Change the nice value of that process to 10.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
