# RHCSA 10 Mock Exam F

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-f` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A RHCSA 10 mock exam focused on RHEL 10 administration, Flatpak, systemd timers, storage, networking, users, security, and services.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - set hostname to clientf.exam10.lab and map serverf.exam10.lab to 192.168 (client) - 5 pts

On client, set hostname to clientf.exam10.lab and map serverf.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.65/24, gateway 192.1 (client) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.65/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - create /root/exam-f-report.txt containing REPORT-F and copy it to server (client) - 5 pts

On client, create /root/exam-f-report.txt containing REPORT-F and copy it to server:/root/exam-f-report.txt.

---

## Question 04 - create a 500 MiB swap partition on /dev/sdc and make it active and persi (client) - 5 pts

On client, create a 500 MiB swap partition on /dev/sdc and make it active and persistent.

---

## Question 05 - Activate the throughput-performance tuned profile (client) - 5 pts

Activate the throughput-performance tuned profile.

---

## Question 06 - Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/ (client) - 5 pts

Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 07 - Ensure org.rhcsa.Tools is not installed after configuring examfflatpak (client) - 5 pts

Ensure org.rhcsa.Tools is not installed after configuring examfflatpak.

---

## Question 08 - enable persistent systemd journal storage (server) - 5 pts

On server, enable persistent systemd journal storage.

---

## Question 09 - Allow %teamf10 to run /usr/bin/systemctl without a password (client) - 5 pts

Allow %teamf10 to run /usr/bin/systemctl without a password.

---

## Question 10 - Create group teamf10, create user userf10, set password cinder9, and add (client) - 5 pts

Create group teamf10, create user userf10, set password cinder9, and add the user to teamf10.

---

## Question 11 - Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10 (client) - 5 pts

Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10.log every 15 minutes.

---

## Question 12 - Create /usr/local/bin/f-who that prints the primary group for the suppli (client) - 5 pts

Create /usr/local/bin/f-who that prints the primary group for the supplied user argument.

---

## Question 13 - set the default boot target to multi-user.target without rebooting (server) - 4 pts

On server, set the default boot target to multi-user.target without rebooting.

---

## Question 14 - Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 4 pts

Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 15 - export /exports/exam-f to the 192.168.122.0/24 network. On client, mount (client + server) - 4 pts

On server, export /exports/exam-f to the 192.168.122.0/24 network. On client, mount server:/exports/exam-f persistently at /mnt/fprojects.

---

## Question 16 - create and enable serverftimer.timer so it appends SERVER-F to /var/log/ (server) - 4 pts

On server, create and enable serverftimer.timer so it appends SERVER-F to /var/log/serverftimer.log every 10 minutes.

---

## Question 17 - publish /var/www/html/server-f.html containing RHCSA10-F and serve httpd (server) - 4 pts

On server, publish /var/www/html/server-f.html containing RHCSA10-F and serve httpd on TCP port 8205.

---

## Question 18 - On client and server, create enabled BaseOS and AppStream repository def (client + server) - 4 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 19 - Set maximum password age for userf10 to 50 days and warning period to 7 (client) - 4 pts

Set maximum password age for userf10 to 50 days and warning period to 7 days.

---

## Question 20 - route local6 log messages to /var/log/server-f-local6.log and write a te (server) - 4 pts

On server, route local6 log messages to /var/log/server-f-local6.log and write a test message.

---

## Question 21 - create /srv/serverf10 owned by root:serverf10 with mode 2770 (server) - 4 pts

On server, create /srv/serverf10 owned by root:serverf10 with mode 2770.

---

## Question 22 - create group serverf10 and user srvf10 with password cinder9, then add t (server) - 4 pts

On server, create group serverf10 and user srvf10 with password cinder9, then add the user to serverf10.
