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

## Question 01 - set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168 (client) - 5 pts

On client, set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.1 (client) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create /root/d-original, hard link /root/d-hard, and symlink /root/d-sof (client) - 5 pts

Create /root/d-original, hard link /root/d-hard, and symlink /root/d-soft.

---

## Question 04 - Create and enable examdtimer.timer that runs every 10 minutes (client) - 4 pts

Create and enable examdtimer.timer that runs every 10 minutes.

---

## Question 05 - Create VG vgd10 and LV datad mounted at /mnt/datad10 (client) - 4 pts

Create VG vgd10 and LV datad mounted at /mnt/datad10.

---

## Question 06 - Create /var/www/html/d.html and restore its default SELinux context (client) - 4 pts

Create /var/www/html/d.html and restore its default SELinux context.

---

## Question 07 - Persistently enable httpd_can_network_connect (client) - 4 pts

Persistently enable httpd_can_network_connect.

---

## Question 08 - Configure persistent systemd journal storage (client) - 4 pts

Configure persistent systemd journal storage.

---

## Question 09 - Use server as the only chrony source and enable chronyd (client) - 4 pts

Use server as the only chrony source and enable chronyd.

---

## Question 10 - Create enabled BaseOS and AppStream repository definitions using http:// (client) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 11 - create and enable a custom systemd service named examd-heartbeat.service (client) - 5 pts

On client, create and enable a custom systemd service named examd-heartbeat.service.

---

## Question 12 - route local5 log messages to /var/log/examd-local5.log and write a test (client) - 5 pts

On client, route local5 log messages to /var/log/examd-local5.log and write a test message.

---

## Question 13 - Create group teamd10, create user userd10, set password cinder9, and add (client) - 5 pts

Create group teamd10, create user userd10, set password cinder9, and add the user to teamd10.

---

## Question 14 - Allow %teamd10 to run /usr/bin/systemctl without a password by using a s (client) - 5 pts

Allow %teamd10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 15 - Set maximum password age for userd10 to 48 days and warning period to 7 (client) - 5 pts

Set maximum password age for userd10 to 48 days and warning period to 7 days.

---

## Question 16 - Create /usr/local/bin/d-who that prints the primary group for the suppli (client) - 5 pts

Create /usr/local/bin/d-who that prints the primary group for the supplied user argument.

---

## Question 17 - Write users whose shell ends with sh to /root/d-shell-users.txt (client) - 5 pts

Write users whose shell ends with sh to /root/d-shell-users.txt.

---

## Question 18 - Create gzip archive /root/d-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 5 pts

Create gzip archive /root/d-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 19 - Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10 (client) - 4 pts

Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10.log every 15 minutes.

---

## Question 20 - configure autofs so /remoted/projects mounts server:/exports/autofs/proj (client) - 4 pts

On client, configure autofs so /remoted/projects mounts server:/exports/autofs/projects.

---

## Question 21 - allow the http service permanently in firewalld and reload the firewall (client) - 4 pts

On client, allow the http service permanently in firewalld and reload the firewall.

---

## Question 22 - Install lsof and ensure tcpdump is removed (client) - 4 pts

Install lsof and ensure tcpdump is removed.
