# Lab 33: Bootloader Kernel Argument

Time: 20 minutes
Objectives: boot-and-recovery
Systems: clientvm

Modify the system bootloader so every installed kernel boots with the required persistent argument.

## Tasks

## Task 01 - Configure the bootloader on clientvm so that every (clientvm) - 10 pts

Configure the bootloader on clientvm so that every installed kernel boots with the kernel argument audit_backlog_limit=8192.

## Task 02 - The change must persist across reboots and must not (clientvm) - 10 pts

The change must persist across reboots and must not require manual GRUB editing during startup.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
