# Lab 34: Journald Persistence and Rsyslog

Time: 25 minutes
Objectives: processes-logs-tuning, software-scheduling-time
Systems: clientvm

Configure persistent journal storage and a custom rsyslog drop-in for authentication warnings.

## Tasks

## Task 01 - Configure journald on clientvm so logs are stored (clientvm) - 10 pts

Configure journald on clientvm so logs are stored persistently across reboots.

## Task 02 - Create the drop-in file (clientvm) - 10 pts

Create the drop-in file /etc/rsyslog.d/10-auth34.conf so authpriv messages with priority warning and higher are written to /var/log/auth34.log.

## Task 03 - Ensure the rsyslog service is active after your (clientvm) - 10 pts

Ensure the rsyslog service is active after your changes.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
