# Mock Exam H

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-h` |
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

- **IP address:** 192.168.122.47/24
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** client-h.exam9.lab

---

## Question 03 - Client RPM Repositories (client) - 5 pts

On client, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 04 - Client Package Management (client) - 5 pts

On client, install lsof from the configured repositories and remove tcpdump if it is installed.

---

## Question 05 - Client Users and Group (client) - 5 pts

On client, create group opsh9. Create users anah9, devh9, and audith9; audith9 must use /sbin/nologin. Set each password to cinder9 and add anah9 and devh9 to opsh9.

---

## Question 06 - Client Password Aging and Sudo (client) - 5 pts

On client, set maximum password age 60 days and warning period 7 days for anah9. Allow members of opsh9 to run /usr/bin/systemctl with sudo without a password.

---

## Question 07 - Client Shared Directory (client) - 5 pts

On client, create /srv/opsh9 owned by root:opsh9 with permissions 2770 and a default ACL granting opsh9 full access.

---

## Question 08 - Client Report Script (client) - 5 pts

On client, create executable script /usr/local/bin/report-h9 that writes harbor jasper report and the active state of sshd, chronyd, and firewalld to /root/report-h9.txt.

---

## Question 09 - Client Swap Persistence (client) - 5 pts

On client, create a 512 MiB swap file at /swaph9, activate it immediately, and make it persistent.

---

## Question 10 - Client LVM Mount (client) - 5 pts

On client, create volume group vgh9 on /dev/sdb, create logical volume datah9 with size 320 MiB, format it as XFS, and mount it persistently at /mnt/datah9.

---

## Question 11 - Client Rootless Container (client) - 5 pts

On client, create user podh9, enable lingering for that user, and run a rootless container named webh9 from localhost/rhcsa-httpd-base:latest.

---

## Question 12 - Server IPv4 Networking (server) - 5 pts

On server, configure persistent IPv4 networking.

- **IP address:** 192.168.122.3/24
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** server-h.exam9.lab

---

## Question 13 - Server RPM Repositories (server) - 4 pts

On server, configure enabled BaseOS and AppStream repositories from http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 14 - Server User and Sudo (server) - 4 pts

On server, create group srvh9, create user svch9 with password cinder9, add svch9 to srvh9, and allow srvh9 to run /usr/bin/systemctl with sudo without a password.

---

## Question 15 - Server Web Service (server) - 4 pts

On server, publish /var/www/html/exam-h.html containing harbor landing web, configure httpd to listen on TCP port 8307, label the port for httpd, and open it permanently in firewalld.

---

## Question 16 - Server Persistent Journal (server) - 4 pts

On server, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 17 - Server Cron Schedule (server) - 4 pts

On server, schedule a root cron job that runs every 12 minutes and appends harbor cycle cron to /var/log/audith9.log.

---

## Question 18 - Server Boot Target and Directory (server) - 4 pts

On server, set the default boot target to multi-user.target and create /srv/server-h9 owned by root:srvh9 with permissions 2770.

---

## Question 19 - Client Server NFS Mount (client + server) - 4 pts

On server, export /exports/rhcsa9-h to 192.168.122.0/24 with a README containing harbor data export. On client, mount server:/exports/rhcsa9-h persistently at /mnt/rhcsa9-h.

---

## Question 20 - Client Server SSH Key (client + server) - 4 pts

On server, create user copyh9 with password cinder9. On client, configure key-based SSH login for root to copyh9@server.

---

## Question 21 - Client Server Secure Copy (client + server) - 4 pts

On client, create /root/exam-h-copy.txt containing harbor mirror transfer and copy it to server:/home/copyh9/exam-h-copy.txt.

---

## Question 22 - Client Server Time Sync (client + server) - 4 pts

On server, enable chronyd for the lab network. On client, configure chronyd to use server as its only time source.
