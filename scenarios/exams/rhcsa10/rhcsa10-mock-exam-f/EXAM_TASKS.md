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

## Question 01 - Set hostname to clientf.exam10.lab and map serverf.exam10.lab to 192.168 (server) - 5 pts

Set hostname to clientf.exam10.lab and map serverf.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.65/24, gateway 192.1 (server) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.65/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Install lsof and ensure tcpdump is removed (server) - 4 pts

Install lsof and ensure tcpdump is removed.

---

## Question 04 - Create and enable examftimer.timer that runs every 10 minutes (server) - 4 pts

Create and enable examftimer.timer that runs every 10 minutes.

---

## Question 05 - Allow TCP port 8105 permanently in firewalld and reload (server) - 4 pts

Allow TCP port 8105 permanently in firewalld and reload.

---

## Question 06 - Persistently enable httpd_can_network_connect (server) - 4 pts

Persistently enable httpd_can_network_connect.

---

## Question 07 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 08 - Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 09 - Install org.rhcsa.Tools from examfflatpak, then remove it after verifica (server) - 5 pts

Install org.rhcsa.Tools from examfflatpak, then remove it after verification.

---

## Question 10 - Create group teamf10, create user userf10, set password cinder9, and add (server) - 5 pts

Create group teamf10, create user userf10, set password cinder9, and add the user to teamf10.

---

## Question 11 - Allow %teamf10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

Allow %teamf10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 12 - Set maximum password age for userf10 to 50 days and warning period to 7 (server) - 5 pts

Set maximum password age for userf10 to 50 days and warning period to 7 days.

---

## Question 13 - Create /usr/local/bin/f-who that prints the primary group for the suppli (server) - 5 pts

Create /usr/local/bin/f-who that prints the primary group for the supplied user argument.

---

## Question 14 - Write users whose shell ends with sh to /root/f-shell-users.txt (server) - 5 pts

Write users whose shell ends with sh to /root/f-shell-users.txt.

---

## Question 15 - Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 16 - Create /root/f-original, hard link /root/f-hard, and symlink /root/f-sof (server) - 5 pts

Create /root/f-original, hard link /root/f-hard, and symlink /root/f-soft.

---

## Question 17 - Create VG vgf10 and LV dataf mounted at /mnt/dataf10 (server) - 4 pts

Create VG vgf10 and LV dataf mounted at /mnt/dataf10.

---

## Question 18 - Create /var/www/html/f.html and restore its default SELinux context (server) - 4 pts

Create /var/www/html/f.html and restore its default SELinux context.

---

## Question 19 - Activate the throughput-performance tuned profile (server) - 4 pts

Activate the throughput-performance tuned profile.

---

## Question 20 - Configure persistent systemd journal storage (server) - 4 pts

Configure persistent systemd journal storage.

---

## Question 21 - Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10 (server) - 4 pts

Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10.log every 15 minutes.

---

## Question 22 - Set the default target to multi-user.target without rebooting (server) - 4 pts

Set the default target to multi-user.target without rebooting.
