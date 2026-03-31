# Boot Targets And Root Recovery - Lab Tasks
Scenario ID: boot-and-recovery
Mode: Lab
Time limit: 45 minutes
Objectives: boot-and-recovery

Practice RHCSA v9 boot target changes and root password recovery from the bootloader path.

## Task 01 - Root Password Reset (clientvm) - 20 pts
Recover administrative access to clientvm by resetting the root password from the GRUB recovery path.

## Task 02 - Normal Boot State (clientvm) - 10 pts
Return the system to a normal boot state and confirm the default target is still multi-user.target or graphical.target.

## Task 03 - Host SSH Access (clientvm) - 10 pts
Confirm Vagrant SSH access to clientvm works again after the successful normal reboot.

Hints
1. A standard RHCSA flow uses rd.break and a writable sysroot.
2. If you change the root password from the emergency path, remember the SELinux relabel step if your method requires it.

Checks
```bash
From the host: vagrant ssh clientvm
Inside clientvm: passwd -S root
Inside clientvm: systemctl get-default
```
