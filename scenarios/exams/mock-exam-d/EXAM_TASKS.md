# Mock Exam D

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-d` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, software-management, storage-lvm |

A 22 task RHCSA style mock exam focused on repository hygiene, account defaults, server service state, and logical volume provisioning.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm) - 5 pts

Configure networking on clientvm with the following settings:

- **IP Address:** 192.168.122.36
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.summit.lab

---

## Question 02 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so mirror.summit.lab resolves to 192.168.122.3.

---

## Question 03 - Client Repositories (clientvm) - 5 pts

Configure a repository file on clientvm with BaseOS and AppStream served from servervm, enabled, and with gpgcheck disabled.

---

## Question 04 - Server Repositories (servervm) - 5 pts

Configure the same repository file on servervm.

---

## Question 05 - Useradd Defaults (clientvm) - 5 pts

Set the default inactive period for newly created local users to 14 days.

---

## Question 06 - No-Home User (clientvm) - 5 pts

Create user trainee54 without a home directory and set its password to cinder9.

---

## Question 07 - Admin User (clientvm) - 5 pts

Create user kara with a home directory and set its password to cinder9.

---

## Question 08 - Delegated Sudo (clientvm) - 5 pts

Allow kara to run /usr/bin/systemctl restart rsyslog and /usr/bin/systemctl status sshd through sudo. Use a sudoers drop-in.

---

## Question 09 - Server Login Messages (servervm) - 5 pts

On servervm, configure both /etc/issue and /etc/motd to contain the line Summit maintenance host.

---

## Question 10 - Server Default Target (servervm) - 5 pts

On servervm, set the default target to multi-user.target, ensure rsyslog is enabled, and ensure postfix is disabled.

---

## Question 11 - Package Management (servervm) - 5 pts

On servervm, install tree and remove dos2unix.

---

## Question 12 - Password Aging Defaults (clientvm) - 5 pts

Set password aging defaults so newly created users have maximum 60 days, minimum 2 days, and warning 7 days.

---

## Question 13 - Forced Password Change (clientvm) - 4 pts

Create user miles with a home directory, set its password to cinder9, and force a password change on first login.

---

## Question 14 - Fixed UID User (clientvm) - 4 pts

Create user cedar540 with UID 4540 and set its password to cinder9.

---

## Question 15 - User Umask (clientvm) - 4 pts

Set a personal umask of 027 for miles.

---

## Question 16 - Audit Directory (clientvm) - 4 pts

Create /srv/summit-audit on clientvm with mode 0750 and ownership root:root.

---

## Question 17 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-d/find that are owned by foragerd and were modified within the last 24 hours. Copy them to /root/foragerd-files while preserving the source directory structure.

---

## Question 18 - Grep Filter (clientvm) - 4 pts

Extract lines containing alpha from /usr/share/dict/words into /root/alpha-lines.

---

## Question 19 - Archive /etc (clientvm) - 4 pts

Create /root/summit-etc.tar.gz containing /etc.

---

## Question 20 - Service Report Script (clientvm) - 4 pts

Create executable script /usr/local/bin/summit-scan that writes the active state of each unit listed in /usr/local/share/exam-d/units.lst to /root/summit-units.txt.

---

## Question 21 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 512 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 22 - LVM Mount (clientvm) - 4 pts

On /dev/sdc, create volume group summitvg and logical volume summitlv with size 256 MiB, format it with ext4, and mount it persistently at /mnt/summitlv.
