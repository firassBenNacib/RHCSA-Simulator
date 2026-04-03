# Mock Exam G: DeltaForge Recovery Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-g` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, filesystems-and-autofs, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam combining recovery, NFS, sticky directories, SSH key transfer, process handling, and rootless containers.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (clientvm) - 5 pts

Recover root access on clientvm from the console.

- **Set the root password to:** cinder9

---

## Question 02 - Client Network (clientvm) - 5 pts

Configure networking on clientvm with the following settings:

- **IP Address:** 192.168.122.39
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.deltaforge.lab

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

Configure the bootloader on clientvm so every installed kernel boots with the kernel argument audit_backlog_limit=8192.

---

## Question 04 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so vault.deltaforge.lab resolves to 192.168.122.3.

---

## Question 05 - Direct NFS Mount (clientvm) - 5 pts

- **Mount the server export servervm:** /exports/delta-home persistently on clientvm at /mnt/delta-home using NFS.

---

## Question 06 - Ops User And Group (clientvm) - 5 pts

Create group deltaops and create user pavel with deltaops as a supplementary group. Set the password of pavel to cinder9.

---

## Question 07 - Sticky Shared Directory (clientvm) - 5 pts

Create /projects/delta-drop owned by root:deltaops with mode 3770 so group ownership is inherited and only file owners can delete their own files.

---

## Question 08 - No-Home Audit User (clientvm) - 5 pts

Create user auditg without a home directory and with login shell /sbin/nologin.

---

## Question 09 - Password Aging (clientvm) - 5 pts

Set password aging for pavel to maximum 45 days, minimum 5 days, and warning 7 days.

---

## Question 10 - User Umask (clientvm) - 5 pts

Set a personal umask of 027 for pavel.

---

## Question 11 - Copy User On Both Systems (clientvm) - 5 pts

Create user copyg on both systems with password cinder9.

---

## Question 12 - SSH Key And Secure Copy (clientvm + servervm) - 5 pts

As copyg on clientvm, generate an ED25519 SSH key pair with no passphrase, install it on servervm, and copy /opt/exam-g/copyg-payload.txt to /home/copyg/inbox/payload.txt on servervm.

---

## Question 13 - At Job (clientvm) - 4 pts

Queue a one-time at job as user pavel that appends the message "DeltaForge tick" to /root/delta-at.log in 2 minutes.

---

## Question 14 - Per-User Login Message (clientvm) - 4 pts

Append a login message for pavel to ~/.bash_profile that prints "DeltaForge access" when pavel logs in.

---

## Question 15 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-g/find that are owned by trackerg and were modified within the last 24 hours, then copy them to /root/trackerg-files while preserving the source directory structure.

---

## Question 16 - Grep Filter (clientvm) - 4 pts

Extract lines containing ember from /usr/share/dict/words into /root/ember-lines.

---

## Question 17 - Archive (clientvm) - 4 pts

Create /root/etc-g.tar.bz2 containing /etc.

---

## Question 18 - Persistent Journal (clientvm) - 4 pts

Configure journald on clientvm so logs are stored persistently across reboots.

---

## Question 19 - Process Renice And Kill (clientvm) - 4 pts

User workerg has a CPU-bound process whose PID is stored in /home/workerg/cpu.pid and a sleep process whose PID is stored in /home/workerg/sleep.pid. Terminate the CPU-bound process and change the nice value of the sleep process to 10.

---

## Question 20 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 736 MiB swap partition and configure it persistently.

---

## Question 21 - Create And Mount LV (clientvm) - 4 pts

On /dev/sdc, create a volume group deltavg with a physical extent size of 16 MiB and a logical volume deltalv with 40 extents. Format it with ext4 and mount it persistently at /mnt/deltalv.

---

## Question 22 - Rootless Container Autostart (clientvm) - 4 pts

As user solg, build localhost/delta-web:latest from /opt/rhcsa/workspaces/exam-g/Containerfile. Run the container as pdfg with /opt/ing mounted to /data/input and /opt/outg mounted to /data/output. Generate and enable a systemd user service for that container and enable lingering for solg.
