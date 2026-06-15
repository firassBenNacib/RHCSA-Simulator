# Mock Exam G

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-g` |
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

## Question 01 - Root Recovery (client) - 5 pts

On client, recover root access from the console and set the root password to cinder9.

---

## Question 02 - Client IPv4 Networking (client) - 5 pts

On client, configure persistent IPv4 networking.

- **IP address:** 192.168.122.46/24
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** client-g.exam9.lab

---

## Question 03 - Client RPM Repositories (client) - 5 pts

On client, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 04 - Client Package Management (client) - 5 pts

On client, install tree from the configured repositories and remove dos2unix if it is installed.

---

## Question 05 - Client Users and Group (client) - 5 pts

On client, create group opsg9. Create users anag9, devg9, and auditg9; auditg9 must use /sbin/nologin. Set each password to cinder9 and add anag9 and devg9 to opsg9.

---

## Question 06 - Client Password Aging and Sudo (client) - 5 pts

On client, set maximum password age 60 days and warning period 7 days for anag9. Allow members of opsg9 to run /usr/bin/systemctl with sudo without a password.

---

## Question 07 - Client Shared Directory (client) - 5 pts

On client, create /srv/opsg9 owned by root:opsg9 with permissions 2770 and a default ACL granting opsg9 full access.

---

## Question 08 - Client Report Script (client) - 5 pts

On client, create executable script /usr/local/bin/report-g9 that writes the active state of sshd, chronyd, and firewalld to /root/report-g9.txt.

---

## Question 09 - Client Swap Persistence (client) - 5 pts

On client, create a 512 MiB swap file at /swapg9, activate it immediately, and make it persistent.

---

## Question 10 - Client LVM Mount (client) - 5 pts

On client, create volume group vgg9 on /dev/sdb, create logical volume datag9 with size 320 MiB, format it as XFS, and mount it persistently at /mnt/datag9.

---

## Question 11 - Client Rootless Container (client) - 5 pts

On client, create user podg9, enable lingering for that user, and run a rootless container named webg9 from localhost/rhcsa-httpd-base:latest.

---

## Question 12 - Server IPv4 Networking (server) - 5 pts

On server, configure persistent IPv4 networking.

- **IP address:** 192.168.122.3/24
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** server-g.exam9.lab

---

## Question 13 - Server RPM Repositories (server) - 4 pts

On server, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 14 - Server User and Sudo (server) - 4 pts

On server, create group srvg9, create user svcg9 with password cinder9, add svcg9 to srvg9, and allow srvg9 to run /usr/bin/systemctl with sudo without a password.

---

## Question 15 - Server Web Service (server) - 4 pts

On server, publish /var/www/html/exam-g.html containing RHCSA9-G, configure httpd to listen on TCP port 8306, label the port for httpd, and open it permanently in firewalld.

---

## Question 16 - Server Persistent Journal (server) - 4 pts

On server, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 17 - Server Cron Schedule (server) - 4 pts

On server, schedule a root cron job that runs every 11 minutes and appends server-g to /var/log/auditg9.log.

---

## Question 18 - Server Boot Target and Directory (server) - 4 pts

On server, set the default boot target to multi-user.target and create /srv/server-g9 owned by root:srvg9 with permissions 2770.

---

## Question 19 - Client Server NFS Mount (client + server) - 4 pts

On server, export /exports/rhcsa9-g to 192.168.122.0/24. On client, mount server:/exports/rhcsa9-g persistently at /mnt/rhcsa9-g.

---

## Question 20 - Client Server SSH Key (client + server) - 4 pts

On server, create user copyg9 with password cinder9. On client, configure key-based SSH login for root to copyg9@server.

---

## Question 21 - Client Server Secure Copy (client + server) - 4 pts

On client, create /root/exam-g-copy.txt containing RHCSA9-G and copy it to server:/home/copyg9/exam-g-copy.txt.

---

## Question 22 - Client Server Time Sync (client + server) - 4 pts

On server, enable chronyd for the lab network. On client, configure chronyd to use server as its only time source.
