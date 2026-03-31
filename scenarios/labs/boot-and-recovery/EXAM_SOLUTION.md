# Boot Targets And Root Recovery - Exam Solution
Scenario ID: boot-and-recovery
Mode: Exam
Time limit: 45 minutes
Objectives: boot-and-recovery

Practice RHCSA v9 boot target changes and root password recovery from the bootloader path.

## Task 01 - Root Password Reset (clientvm) - 20 pts
```bash
# Reboot clientvm and stop at the GRUB menu.
# Edit the active kernel entry, append rd.break, then boot with Ctrl+x.
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
exit
exit
```

## Task 02 - Normal Boot State (clientvm) - 10 pts
```bash
# Let the relabel complete and log in normally as root with the new password.
systemctl get-default
```

## Task 03 - Host SSH Access (clientvm) - 10 pts
```bash
# Run this from the host after the normal reboot finishes.
vagrant ssh clientvm
```
