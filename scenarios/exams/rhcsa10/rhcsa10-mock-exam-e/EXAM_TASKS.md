# RHCSA 10 Mock Exam E

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-e` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Storage and boot focus: labeled filesystem persistence, kernel arguments, LVM, NFS, documentation, package administration, users, scheduling, and logging.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Set hostname to cliente.exam10.lab and map servere.exam10.lab to 192.168 (client) - 5 pts

On client, set hostname to cliente.exam10.lab and map servere.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.64/24, gateway 192.1 (client) - 5 pts

On client, configure System eth1 with IPv4 address 192.168.122.64/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create enabled BaseOS and AppStream repository definitions with BaseOS a (client + server) - 5 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 04 - Create a labeled XFS filesystem on /dev/sdc1 and mount it persistently a (client) - 5 pts

On client, create a labeled XFS filesystem on /dev/sdc1 and mount it persistently at /mnt/exame-label.

---

## Question 05 - Add audit_backlog_limit=8192 to all installed kernel entries (client) - 5 pts

On client, add audit_backlog_limit=8192 to all installed kernel entries.

---

## Question 06 - Create group teame10, create user usere10, set password cinder9, and add (client) - 5 pts

On client, create group teame10, create user usere10, set password cinder9, and add the user to teame10.

---

## Question 07 - Create group servere10 and user srve10 with password cinder9, then add t (server) - 5 pts

On server, create group servere10 and user srve10 with password cinder9, then add the user to servere10.

---

## Question 08 - Allow members of servere10 to run /usr/bin/systemctl with sudo without a (server) - 5 pts

On server, allow members of servere10 to run /usr/bin/systemctl with sudo without a password.

---

## Question 09 - Create /usr/local/bin/e-who that prints the primary group for the suppli (client) - 4 pts

On client, create /usr/local/bin/e-who that prints the primary group for the supplied user argument.

---

## Question 10 - Write users whose shell ends with sh to /root/e-shell-users.txt (client) - 4 pts

On client, write users whose shell ends with sh to /root/e-shell-users.txt.

---

## Question 11 - Create gzip archive /root/e-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 4 pts

On client, create gzip archive /root/e-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 12 - Create /root/e-original, hard link /root/e-hard, and symlink /root/e-sof (client) - 4 pts

On client, create /root/e-original, hard link /root/e-hard, and symlink /root/e-soft.

---

## Question 13 - Create and enable serveretimer.timer so it appends SERVER-E to /var/log/ (server) - 4 pts

On server, create and enable serveretimer.timer so it appends SERVER-E to /var/log/serveretimer.log every 10 minutes.

---

## Question 14 - Create VG vge10 and LV datae mounted at /mnt/datae10 (client) - 4 pts

On client, create VG vge10 and LV datae mounted at /mnt/datae10.

---

## Question 15 - Publish /var/www/html/server-e.html containing RHCSA10-E and serve httpd (server) - 4 pts

On server, publish /var/www/html/server-e.html containing RHCSA10-E and serve httpd on TCP port 8204.

---

## Question 16 - Create /srv/servere10 owned by root:servere10 with mode 2770 (server) - 4 pts

On server, create /srv/servere10 owned by root:servere10 with mode 2770.

---

## Question 17 - Activate the throughput-performance tuned profile (client) - 4 pts

On client, activate the throughput-performance tuned profile.

---

## Question 18 - Route local5 log messages to /var/log/server-e-local5.log and write a te (server) - 4 pts

On server, route local5 log messages to /var/log/server-e-local5.log and write a test message.

---

## Question 19 - Export /exports/exam-e to the 192.168.122.0/24 network. on client, mount (client + server) - 4 pts

On server, export /exports/exam-e to the 192.168.122.0/24 network. On client, mount server:/exports/exam-e persistently at /mnt/eprojects.

---

## Question 20 - Create /root/exam-e-report.txt containing REPORT-E and copy it to server (client + server) - 4 pts

On client, create /root/exam-e-report.txt containing REPORT-E and copy it to server:/root/exam-e-report.txt.

---

## Question 21 - Install lsof and ensure tcpdump is removed (client) - 4 pts

On client, install lsof and ensure tcpdump is removed.

---

## Question 22 - Enable persistent systemd journal storage (server) - 4 pts

On server, enable persistent systemd journal storage.

---

## Question 23 - Add a hosts entry for servere.exam10.lab and save the output of http://s (client + server) - 4 pts

On client, add a hosts entry for servere.exam10.lab and save the output of http://servere.exam10.lab:8204/server-e.html to /root/server-e-web-check.txt.
