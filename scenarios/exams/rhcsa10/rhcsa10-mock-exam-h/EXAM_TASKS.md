# RHCSA 10 Mock Exam H

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-h` |
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

## Question 01 - Set hostname to clienth.exam10.lab and map serverh.exam10.lab to 192.168 (server) - 5 pts

Set hostname to clienth.exam10.lab and map serverh.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.67/24, gateway 192.1 (server) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.67/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create system Flatpak remote examhflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

Create system Flatpak remote examhflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 04 - Install org.rhcsa.Tools from examhflatpak, then remove it after verifica (server) - 5 pts

Install org.rhcsa.Tools from examhflatpak, then remove it after verification.

---

## Question 05 - Create and enable examhtimer.timer that runs every 10 minutes (server) - 4 pts

Create and enable examhtimer.timer that runs every 10 minutes.

---

## Question 06 - Create group teamh10, create user userh10, set password cinder9, and add (server) - 5 pts

Create group teamh10, create user userh10, set password cinder9, and add the user to teamh10.

---

## Question 07 - Set maximum password age for userh10 to 52 days and warning period to 7 (server) - 5 pts

Set maximum password age for userh10 to 52 days and warning period to 7 days.

---

## Question 08 - Persistently enable httpd_can_network_connect (server) - 4 pts

Persistently enable httpd_can_network_connect.

---

## Question 09 - Write users whose shell ends with sh to /root/h-shell-users.txt (server) - 5 pts

Write users whose shell ends with sh to /root/h-shell-users.txt.

---

## Question 10 - Configure persistent systemd journal storage (server) - 4 pts

Configure persistent systemd journal storage.

---

## Question 11 - Create /root/h-original, hard link /root/h-hard, and symlink /root/h-sof (server) - 5 pts

Create /root/h-original, hard link /root/h-hard, and symlink /root/h-soft.

---

## Question 12 - Create a cron job for userh10 that writes EXAM10 to /home/userh10/exam10 (server) - 4 pts

Create a cron job for userh10 that writes EXAM10 to /home/userh10/exam10.log every 15 minutes.

---

## Question 13 - Create VG vgh10 and LV datah mounted at /mnt/datah10 (server) - 4 pts

Create VG vgh10 and LV datah mounted at /mnt/datah10.

---

## Question 14 - Set the default target to multi-user.target without rebooting (server) - 4 pts

Set the default target to multi-user.target without rebooting.

---

## Question 15 - Activate the throughput-performance tuned profile (server) - 4 pts

Activate the throughput-performance tuned profile.

---

## Question 16 - Install lsof and ensure tcpdump is removed (server) - 4 pts

Install lsof and ensure tcpdump is removed.

---

## Question 17 - Use server as the only chrony source and enable chronyd (server) - 4 pts

Use server as the only chrony source and enable chronyd.

---

## Question 18 - Allow TCP port 8107 permanently in firewalld and reload (server) - 4 pts

Allow TCP port 8107 permanently in firewalld and reload.

---

## Question 19 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 20 - Allow %teamh10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

Allow %teamh10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 21 - Create /usr/local/bin/h-who that prints the primary group for the suppli (server) - 5 pts

Create /usr/local/bin/h-who that prints the primary group for the supplied user argument.

---

## Question 22 - Create gzip archive /root/h-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

Create gzip archive /root/h-etc.tar.gz containing /etc/hosts and /etc/fstab.
