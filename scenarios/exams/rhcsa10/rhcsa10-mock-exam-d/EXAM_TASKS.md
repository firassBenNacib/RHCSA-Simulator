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

## Question 01 - Set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168 (client) - 5 pts

On client, set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.1 (client) - 5 pts

On client, configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create /root/d-original, hard link /root/d-hard, and symlink /root/d-sof (client) - 5 pts

On client, create /root/d-original, hard link /root/d-hard, and symlink /root/d-soft.

---

## Question 04 - Create and enable serverdtimer.timer so it appends SERVER-D to /var/log/ (server) - 5 pts

On server, create and enable serverdtimer.timer so it appends SERVER-D to /var/log/serverdtimer.log every 10 minutes.

---

## Question 05 - Create VG vgd10 and LV datad mounted at /mnt/datad10 (client) - 5 pts

On client, create VG vgd10 and LV datad mounted at /mnt/datad10.

---

## Question 06 - Create /var/www/html/d.html and restore its default SELinux context (client) - 5 pts

On client, create /var/www/html/d.html and restore its default SELinux context.

---

## Question 07 - Persistently enable httpd_can_network_connect (client) - 5 pts

On client, persistently enable httpd_can_network_connect.

---

## Question 08 - Enable persistent systemd journal storage (server) - 5 pts

On server, enable persistent systemd journal storage.

---

## Question 09 - Make chronyd available as the lab time source. on client, configure chro (client + server) - 5 pts

On server, make chronyd available as the lab time source. On client, configure chronyd with server as its only time source.

---

## Question 10 - Create enabled BaseOS and AppStream repository definitions with BaseOS a (client + server) - 5 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 11 - Publish /var/www/html/server-d.html containing RHCSA10-D and serve httpd (server) - 5 pts

On server, publish /var/www/html/server-d.html containing RHCSA10-D and serve httpd on TCP port 8203.

---

## Question 12 - Route local5 log messages to /var/log/server-d-local5.log and write a te (server) - 5 pts

On server, route local5 log messages to /var/log/server-d-local5.log and write a test message.

---

## Question 13 - Create group teamd10, create user userd10, set password cinder9, and add (client) - 4 pts

On client, create group teamd10, create user userd10, set password cinder9, and add the user to teamd10.

---

## Question 14 - Allow members of serverd10 to run /usr/bin/systemctl with sudo without a (server) - 4 pts

On server, allow members of serverd10 to run /usr/bin/systemctl with sudo without a password.

---

## Question 15 - Create group serverd10 and user srvd10 with password cinder9, then add t (server) - 4 pts

On server, create group serverd10 and user srvd10 with password cinder9, then add the user to serverd10.

---

## Question 16 - Create /usr/local/bin/d-who that prints the primary group for the suppli (client) - 4 pts

On client, create /usr/local/bin/d-who that prints the primary group for the supplied user argument.

---

## Question 17 - Write users whose shell ends with sh to /root/d-shell-users.txt (client) - 4 pts

On client, write users whose shell ends with sh to /root/d-shell-users.txt.

---

## Question 18 - Create /root/exam-d-report.txt containing REPORT-D and copy it to server (client + server) - 4 pts

On client, create /root/exam-d-report.txt containing REPORT-D and copy it to server:/root/exam-d-report.txt.

---

## Question 19 - Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10 (client) - 4 pts

On client, create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10.log every 15 minutes.

---

## Question 20 - Export /exports/exam-d to the 192.168.122.0/24 network. on client, mount (client + server) - 4 pts

On server, export /exports/exam-d to the 192.168.122.0/24 network. On client, mount server:/exports/exam-d persistently at /mnt/dprojects.

---

## Question 21 - Set the default boot target to multi-user.target without rebooting (server) - 4 pts

On server, set the default boot target to multi-user.target without rebooting.

---

## Question 22 - Install lsof and ensure tcpdump is removed (client) - 4 pts

On client, install lsof and ensure tcpdump is removed.
