# RHCSA 10 Mock Exam D

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-d` |
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

## Question 01 - Set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168 (server) - 5 pts

Set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.1 (server) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.63/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create /root/d-original, hard link /root/d-hard, and symlink /root/d-sof (server) - 5 pts

Create /root/d-original, hard link /root/d-hard, and symlink /root/d-soft.

---

## Question 04 - Create and enable examdtimer.timer that runs every 10 minutes (server) - 4 pts

Create and enable examdtimer.timer that runs every 10 minutes.

---

## Question 05 - Create VG vgd10 and LV datad mounted at /mnt/datad10 (server) - 4 pts

Create VG vgd10 and LV datad mounted at /mnt/datad10.

---

## Question 06 - Create /var/www/html/d.html and restore its default SELinux context (server) - 4 pts

Create /var/www/html/d.html and restore its default SELinux context.

---

## Question 07 - Persistently enable httpd_can_network_connect (server) - 4 pts

Persistently enable httpd_can_network_connect.

---

## Question 08 - Configure persistent systemd journal storage (server) - 4 pts

Configure persistent systemd journal storage.

---

## Question 09 - Use server as the only chrony source and enable chronyd (server) - 4 pts

Use server as the only chrony source and enable chronyd.

---

## Question 10 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 11 - Create system Flatpak remote examdflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

Create system Flatpak remote examdflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 12 - Ensure org.rhcsa.Tools is not installed after configuring examdflatpak (server) - 5 pts

Ensure org.rhcsa.Tools is not installed after configuring examdflatpak.

---

## Question 13 - Create group teamd10, create user userd10, set password cinder9, and add (server) - 5 pts

Create group teamd10, create user userd10, set password cinder9, and add the user to teamd10.

---

## Question 14 - Allow %teamd10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

Allow %teamd10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 15 - Set maximum password age for userd10 to 48 days and warning period to 7 (server) - 5 pts

Set maximum password age for userd10 to 48 days and warning period to 7 days.

---

## Question 16 - Create /usr/local/bin/d-who that prints the primary group for the suppli (server) - 5 pts

Create /usr/local/bin/d-who that prints the primary group for the supplied user argument.

---

## Question 17 - Write users whose shell ends with sh to /root/d-shell-users.txt (server) - 5 pts

Write users whose shell ends with sh to /root/d-shell-users.txt.

---

## Question 18 - Create gzip archive /root/d-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

Create gzip archive /root/d-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 19 - Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10 (server) - 4 pts

Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10.log every 15 minutes.

---

## Question 20 - Configure autofs so /remoted/projects mounts server:/exports/autofs/proj (server) - 4 pts

Configure autofs so /remoted/projects mounts server:/exports/autofs/projects.

---

## Question 21 - Set the default target to multi-user.target without rebooting (server) - 4 pts

Set the default target to multi-user.target without rebooting.

---

## Question 22 - Install lsof and ensure tcpdump is removed (server) - 4 pts

Install lsof and ensure tcpdump is removed.
