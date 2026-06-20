# Mock Exam C

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, software-management, users-sudo-ssh, storage-lvm, containers |

A 22-task RHCSA9 mock exam covering persistent networking, repositories, users, services, storage, NFS, SSH, and rootless containers across client and server.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root recovery (client) - 5 pts

On client, recover root access from the console and set the root password to cinder9.

---

## Question 02 - Client IPv4 networking (client) - 5 pts

On client, configure persistent IPv4 networking.

- **IP address:** 192.168.122.42/24
- **Gateway:** 192.168.122.1
- **DNS:** 192.168.122.3
- **Hostname:** client-c.exam9.lab

---

## Question 03 - Client RPM repositories (client) - 5 pts

On client, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 04 - Client package management (client) - 5 pts

On client, install lsof from the configured repositories and remove dos2unix if it is installed.

---

## Question 05 - Client users and group (client) - 5 pts

On client, create group opsc9. Create users anac9, devc9, and auditc9; auditc9 must use /sbin/nologin. Set each password to cinder9 and add anac9 and devc9 to opsc9.

---

## Question 06 - Client password aging and sudo (client) - 5 pts

On client, set maximum password age 60 days and warning period 7 days for anac9. Allow members of opsc9 to run /usr/bin/systemctl with sudo without a password.

---

## Question 07 - Client shared directory (client) - 5 pts

On client, create /srv/opsc9 owned by root:opsc9 with permissions 2770 and a default ACL granting opsc9 full access.

---

## Question 08 - Client report script (client) - 5 pts

On client, create executable script /usr/local/bin/report-c9 that writes cedar cobalt report and the active state of sshd, chronyd, and firewalld to /root/report-c9.txt.

---

## Question 09 - Client swap persistence (client) - 5 pts

On client, create a 512 MiB swap file at /swapc9, activate it immediately, and make it persistent.

---

## Question 10 - Client LVM mount (client) - 5 pts

On client, create volume group vgc9 on /dev/sdb, create logical volume datac9 with size 320 MiB, format it as XFS, and mount it persistently at /mnt/datac9.

---

## Question 11 - Client rootless container (client) - 5 pts

On client, create user podc9, enable lingering for that user, and run a rootless container named webc9 from localhost/rhcsa-httpd-base:latest.

---

## Question 12 - Server IPv4 networking (server) - 5 pts

On server, configure persistent IPv4 networking.

- **IP address:** 192.168.122.3/24
- **Gateway:** 192.168.122.1
- **DNS:** 192.168.122.3
- **Hostname:** server-c.exam9.lab

---

## Question 13 - Server RPM repositories (server) - 4 pts

On server, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 14 - Server user and sudo (server) - 4 pts

On server, create group srvc9, create user svcc9 with password cinder9, add svcc9 to srvc9, and allow srvc9 to run /usr/bin/systemctl with sudo without a password.

---

## Question 15 - Server web service (server) - 4 pts

On server, publish /var/www/html/exam-c.html containing cedar pulse web, configure httpd to listen on TCP port 8302, label the port for httpd, and open it permanently in firewalld.

---

## Question 16 - Server persistent journal (server) - 4 pts

On server, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 17 - Server cron schedule (server) - 4 pts

On server, schedule a root cron job that runs every 7 minutes and appends cedar timer cron to /var/log/auditc9.log.

---

## Question 18 - Server boot target and directory (server) - 4 pts

On server, set the default boot target to multi-user.target and create /srv/server-c9 owned by root:srvc9 with permissions 2770.

---

## Question 19 - Client server NFS mount (client + server) - 4 pts

On server, export /exports/rhcsa9-c to 192.168.122.0/24 with a README containing cedar files export. On client, mount server:/exports/rhcsa9-c persistently at /mnt/rhcsa9-c.

---

## Question 20 - Client server SSH key (client + server) - 4 pts

On server, create user copyc9 with password cinder9. On client, configure key-based SSH login for root to copyc9@server.

---

## Question 21 - Client server secure copy (client + server) - 4 pts

On client, create /root/exam-c-copy.txt containing cedar bridge transfer and copy it to server:/home/copyc9/exam-c-copy.txt.

---

## Question 22 - Client server time sync (client + server) - 4 pts

On server, enable chronyd for the lab network. On client, configure chronyd to use server as its only time source.
