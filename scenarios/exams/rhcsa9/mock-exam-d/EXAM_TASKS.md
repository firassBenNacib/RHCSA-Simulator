# Mock Exam D

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-d` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, software-management, storage-lvm |

A 22-task RHCSA practice mock exam focused on repository hygiene, account defaults, server service state, and logical volume provisioning.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (client) - 5 pts

On client, configure networking on client with the following settings:

- **IP Address:** 192.168.122.36
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** client.summit.lab

---

## Question 02 - Host Entry (client) - 5 pts

On client, add a persistent hosts entry so mirror.summit.lab resolves to 192.168.122.3.

---

## Question 03 - Client Repositories (client) - 5 pts

On client, configure a repository file on client with BaseOS and AppStream served from server, enabled, and with gpgcheck disabled.

---

## Question 04 - Server Repositories (server) - 5 pts

On server, configure the same repository file on server.

---

## Question 05 - Useradd Defaults (client) - 5 pts

On client, set the default inactive period for newly created local users to 14 days.

---

## Question 06 - No-Home User (client) - 5 pts

On client, create user trainee54 without a home directory and set its password to cinder9.

---

## Question 07 - Admin User (client) - 5 pts

On client, create user kara with a home directory and set its password to cinder9.

---

## Question 08 - Delegated Sudo (client) - 5 pts

On client, allow kara to run /usr/bin/systemctl restart rsyslog and /usr/bin/systemctl status sshd through sudo. Use a sudoers drop-in.

---

## Question 09 - Server Login Messages (server) - 5 pts

On server, configure both /etc/issue and /etc/motd to contain the line Summit maintenance host.

---

## Question 10 - Server Default Target (server) - 5 pts

On server, set the default target to multi-user.target, ensure rsyslog is enabled, and ensure postfix is disabled.

---

## Question 11 - Package Management (server) - 5 pts

On server, install tree and remove dos2unix.

---

## Question 12 - Password Aging Defaults (client) - 5 pts

On client, set password aging defaults so newly created users have maximum 60 days, minimum 2 days, and warning 7 days.

---

## Question 13 - Forced Password Change (client) - 4 pts

On client, create user miles with a home directory, set its password to cinder9, and force a password change on first login.

---

## Question 14 - Fixed UID User (client) - 4 pts

On client, create user cedar540 with UID 4540 and set its password to cinder9.

---

## Question 15 - User Umask (client) - 4 pts

On client, set a personal umask of 027 for miles.

---

## Question 16 - Audit Directory (client) - 4 pts

On client, create /srv/summit-audit on client with mode 0750 and ownership root:root.

---

## Question 17 - Find and Copy (client) - 4 pts

On client, find all files under /opt/exam-d/find that are owned by foragerd and were modified within the last 24 hours. Copy them to /root/foragerd-files while preserving the source directory structure.

---

## Question 18 - Grep Filter (client) - 4 pts

On client, extract lines containing alpha from /usr/share/dict/words into /root/alpha-lines.

---

## Question 19 - Archive (client) - 4 pts

On client, create /root/summit-etc.tar.gz containing /etc.

---

## Question 20 - Shell Script (client) - 4 pts

On client, create executable script /usr/local/bin/summit-scan that writes the active state of each unit listed in /usr/local/share/exam-d/units.lst to /root/summit-units.txt.

---

## Question 21 - Swap Space (client) - 4 pts

On client, on /dev/sdb, create a 512 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 22 - Create and Mount LV (client) - 4 pts

On client, on /dev/sdc, create a volume group summitvg with a physical extent size of 16 MiB and a logical volume summitlv of 16 extents. Format it with xfs and mount it persistently on /mnt/summitlv.
