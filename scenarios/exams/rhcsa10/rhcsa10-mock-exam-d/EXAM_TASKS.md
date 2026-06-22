# RHCSA 10 Mock Exam D

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-d` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Service and logging focus: custom systemd service, rsyslog routing, firewall service access, SELinux, journald, chrony, storage, users, and package administration.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Recover root password (client) - 5 pts

On client, recover root access and configure the client hostname. Set the root password to cinder9. Then set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure eth1 networking (client) - 5 pts

On client, configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create /root/d-original, hard link /root/d-hard, and symlink (client) - 5 pts

On client, create /root/d-original, hard link /root/d-hard, and symlink /root/d-soft.

---

## Question 04 - Configure systemd timer (server) - 5 pts

On server, create and enable serverdtimer.timer so it appends SERVER-D to /var/log/serverdtimer.log every 10 minutes.

---

## Question 05 - Configure LVM storage (client) - 5 pts

On client, create physical volume on /dev/sdb, volume group vgd10, logical volume datad of 384 MiB, format it with XFS, and mount it persistently at /mnt/datad10.

---

## Question 06 - Create /var/www/html/d.html and restore its default SELinux context (client) - 5 pts

On client, create /var/www/html/d.html and restore its default SELinux context.

---

## Question 07 - Persist SELinux boolean (client) - 5 pts

On client, persistently enable httpd_can_network_connect.

---

## Question 08 - Enable persistent journal (server) - 5 pts

On server, enable persistent systemd journal storage.

---

## Question 09 - Configure chrony time source (client + server) - 5 pts

On server, make chronyd available as the lab time source. On client, configure chronyd with server as its only time source.

---

## Question 10 - Configure BaseOS and AppStream repositories (client + server) - 5 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 11 - Publish web content (server) - 5 pts

On server, publish /var/www/html/server-d.html containing RHCSA10-D and serve httpd on TCP port 8203.

---

## Question 12 - Route rsyslog messages (server) - 5 pts

On server, route local5 log messages to /var/log/server-d-local5.log and write a test message.

---

## Question 13 - Create user and group (client) - 4 pts

On client, create group teamd10, create user userd10, set password cinder9, and add the user to teamd10.

---

## Question 14 - Configure sudo access (server) - 4 pts

On server, allow members of serverd10 to run /usr/bin/systemctl with sudo without a password.

---

## Question 15 - Create user and group (server) - 4 pts

On server, create group serverd10 and user srvd10 with password cinder9, then add the user to serverd10.

---

## Question 16 - Create user lookup script (client) - 4 pts

On client, create /usr/local/bin/d-who that prints the primary group for the supplied user argument.

---

## Question 17 - Write users whose shell ends with sh to /root/d-shell-users.txt (client) - 4 pts

On client, write users whose shell ends with sh to /root/d-shell-users.txt.

---

## Question 18 - Copy exam report to server (client + server) - 4 pts

On client, create /root/exam-d-report.txt containing REPORT-D and copy it to server:/root/exam-d-report.txt.

---

## Question 19 - Schedule cron job (client) - 4 pts

On client, create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10.log every 15 minutes.

---

## Question 20 - Configure NFS export and mount (client + server) - 4 pts

On server, export /exports/exam-d to the 192.168.122.0/24 network. On client, mount server:/exports/exam-d persistently at /mnt/dprojects.

---

## Question 21 - Set the default boot target to multi-user.target without rebooting (server) - 4 pts

On server, set the default boot target to multi-user.target without rebooting.

---

## Question 22 - Install lsof and ensure tcpdump is removed (client) - 4 pts

On client, install lsof and ensure tcpdump is removed.
