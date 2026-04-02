# Lab 06: Shared Setgid Directory

Time: 25 minutes
Objectives: filesystems-and-autofs
Systems: clientvm

Create a collaborative directory that preserves group ownership.

## Tasks

## Task 01 - Create /shared/analysts with group ownership of (clientvm) - 10 pts

Create /shared/analysts with group ownership of analystsx and allow access only to root and members of analystsx.

## Task 02 - Set the directory so new files inherit the (clientvm) - 10 pts

Set the directory so new files inherit the analystsx group automatically.

## Task 03 - Verify the final directory permissions (clientvm) - 10 pts

Verify the final directory permissions.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
