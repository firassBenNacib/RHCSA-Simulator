# Mock Exam C

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, filesystems-and-autofs, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam centered on recovery, boot persistence, NFS, ACLs, journald, and rootless containers.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (clientvm) - 5 pts

Recover root access on clientvm from the console.

Set the root password to: cinder9

---

## Question 02 - Client Network (clientvm) - 5 pts

Configure networking on clientvm with the following settings:

- **IP Address:** 192.168.122.28
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.exam-c.lab

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

Configure the bootloader on clientvm so every installed kernel boots with the kernel argument audit_backlog_limit=8192.

---

## Question 04 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so vault.exam-c.lab resolves to 192.168.122.3.

---

## Question 05 - Direct NFS Mount (clientvm) - 5 pts

- **Persistently mount servervm:** /exports/bluec on /mnt/bluec using /etc/fstab.

---

## Question 06 - Users And Group (clientvm) - 5 pts

Create group infrac and users talia and ren with infrac as a supplementary group. Set the password of both users to cinder9.

---

## Question 07 - Default ACL Directory (clientvm) - 5 pts

Create /srv/infrac owned by root:infrac with mode 2770 and a default ACL that grants group infrac rwx on new files and directories.

---

## Question 08 - No-Home User (clientvm) - 5 pts

Create user remote63 without a home directory and with login shell /sbin/nologin.

---

## Question 09 - At Job (clientvm) - 5 pts

Queue a one-time at job as user ren that appends the message "exam-c audit" to /root/exam-c-at.log in 2 minutes.

---

## Question 10 - Per-User Password Aging (clientvm) - 5 pts

Set password aging for talia to maximum 45 days, minimum 5 days, warning 7 days.

---

## Question 11 - Persistent Journal (servervm) - 5 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 12 - User Umask (clientvm) - 5 pts

Set a personal umask of 027 for user ren.

---

## Question 13 - Per-User Login Message (clientvm) - 4 pts

Append a login message for ren to ~/.bash_profile that prints "exam-c access" when ren logs in.

---

## Question 14 - Fixed UID User (clientvm) - 4 pts

Create user kian431 with UID 4431 and set its password to cinder9.

---

## Question 15 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-c/find that are owned by ren and were modified in the last 24 hours, then copy them to /root/ren-files while preserving the directory structure.

---

## Question 16 - Grep Filter (clientvm) - 4 pts

Extract lines containing orbit from /usr/share/dict/words into /root/orbit-lines.

---

## Question 17 - Archive (clientvm) - 4 pts

Create /root/etc-c.tar.bz2 containing /etc.

---

## Question 18 - Service Status Script (clientvm) - 4 pts

Create executable script /usr/local/bin/northcheck that writes the active state of each service listed in /usr/local/share/exam-c/check.lst to /root/north-services.txt.

---

## Question 19 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 700 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 20 - Resize Existing LV (clientvm) - 4 pts

Resize /dev/reviewvgc/reviewc so the final size is 340 MiB without losing data.

---

## Question 21 - Rootless Container (clientvm) - 4 pts

As user eirac, build localhost/northstar-web:latest from /opt/rhcsa/workspaces/exam-c/Containerfile, then run container pdfc with /opt/inc mounted to /data/input and /opt/outc mounted to /data/output.

---

## Question 22 - Container Autostart (clientvm) - 4 pts

Generate and enable a systemd user service for pdfc and enable lingering for eirac.
