# Lab 27: At Job Scheduling

Time: 20 minutes
Objectives: software-scheduling-time
Systems: clientvm

Schedule a one time task with at and verify that the at daemon is enabled.

## Tasks

## Task 01 - Create the user queue27 and set its password to (clientvm) - 10 pts

Create the user queue27 and set its password to cinder9.

## Task 02 - Enable and start the atd service (clientvm) - 10 pts

Enable and start the atd service.

## Task 03 - schedule a one-time at job that appends the text (clientvm) - 10 pts

As user queue27, schedule a one-time at job that appends the text AT27 OK to /home/queue27/at27.log two minutes from now.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
