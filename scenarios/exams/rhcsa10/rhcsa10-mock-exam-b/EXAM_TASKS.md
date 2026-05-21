# RHCSA 10 Mock Exam B

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-b` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A RHCSA 10 mock exam focused on RHEL 10 administration, Flatpak, systemd timers, storage, networking, users, security, and services.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Set hostname to clientb.exam10.lab and map serverb.exam10.lab to 192.168 (server) - 5 pts

Set hostname to clientb.exam10.lab and map serverb.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.61/24, gateway 192.1 (server) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.61/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 04 - Create system Flatpak remote exambflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

Create system Flatpak remote exambflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 05 - Install org.rhcsa.Tools from exambflatpak, then remove it after verifica (server) - 5 pts

Install org.rhcsa.Tools from exambflatpak, then remove it after verification.

---

## Question 06 - Create group teamb10, create user userb10, set password cinder9, and add (server) - 5 pts

Create group teamb10, create user userb10, set password cinder9, and add the user to teamb10.

---

## Question 07 - Allow %teamb10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

Allow %teamb10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 08 - Set maximum password age for userb10 to 46 days and warning period to 7 (server) - 5 pts

Set maximum password age for userb10 to 46 days and warning period to 7 days.

---

## Question 09 - Create /usr/local/bin/b-who that prints the primary group for the suppli (server) - 5 pts

Create /usr/local/bin/b-who that prints the primary group for the supplied user argument.

---

## Question 10 - Write users whose shell ends with sh to /root/b-shell-users.txt (server) - 5 pts

Write users whose shell ends with sh to /root/b-shell-users.txt.

---

## Question 11 - Create gzip archive /root/b-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

Create gzip archive /root/b-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 12 - Create /root/b-original, hard link /root/b-hard, and symlink /root/b-sof (server) - 5 pts

Create /root/b-original, hard link /root/b-hard, and symlink /root/b-soft.

---

## Question 13 - Create and enable exambtimer.timer that runs every 10 minutes (server) - 4 pts

Create and enable exambtimer.timer that runs every 10 minutes.

---

## Question 14 - Create VG vgb10 and LV datab mounted at /mnt/datab10 (server) - 4 pts

Create VG vgb10 and LV datab mounted at /mnt/datab10.

---

## Question 15 - Create /var/www/html/b.html and restore its default SELinux context (server) - 4 pts

Create /var/www/html/b.html and restore its default SELinux context.

---

## Question 16 - Persistently enable httpd_can_network_connect (server) - 4 pts

Persistently enable httpd_can_network_connect.

---

## Question 17 - Activate the throughput-performance tuned profile (server) - 4 pts

Activate the throughput-performance tuned profile.

---

## Question 18 - Configure persistent systemd journal storage (server) - 4 pts

Configure persistent systemd journal storage.

---

## Question 19 - Create a cron job for userb10 that writes EXAM10 to /home/userb10/exam10 (server) - 4 pts

Create a cron job for userb10 that writes EXAM10 to /home/userb10/exam10.log every 15 minutes.

---

## Question 20 - Mount server:/exports/direct at /mnt/bdirect persistently (server) - 4 pts

- **Mount server:** /exports/direct at /mnt/bdirect persistently.

---

## Question 21 - Set the default target to multi-user.target without rebooting (server) - 4 pts

Set the default target to multi-user.target without rebooting.

---

## Question 22 - Install lsof and ensure tcpdump is removed (server) - 4 pts

Install lsof and ensure tcpdump is removed.
