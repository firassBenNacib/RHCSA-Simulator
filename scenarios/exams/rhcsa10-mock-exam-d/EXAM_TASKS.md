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
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Configure hostname and hosts entry (server) - 5 pts

Set hostname to clientd.exam10.lab and map serverd.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure IPv4 profile (server) - 5 pts

Set System eth1 to 192.168.122.63/24 with gateway 192.168.122.1 and DNS 192.168.122.3.

---

## Question 03 - Configure RPM repositories (server) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 04 - Configure Flatpak remote (server) - 5 pts

Create system Flatpak remote examdflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 05 - Install and remove Flatpak app (server) - 5 pts

Install org.rhcsa.Tools from examdflatpak, then remove it after verification.

---

## Question 06 - Create user and group (server) - 5 pts

Create group teamd10, create user userd10, set password cinder9, and add the user to teamd10.

---

## Question 07 - Delegate sudo access (server) - 5 pts

Allow %teamd10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 08 - Set password aging (server) - 5 pts

Set maximum password age for userd10 to 48 days and warning period to 7 days.

---

## Question 09 - Create argument script (server) - 5 pts

Create /usr/local/bin/d-who that prints the primary group for the supplied user argument.

---

## Question 10 - Filter shell users (server) - 5 pts

Write users whose shell ends with sh to /root/d-shell-users.txt.

---

## Question 11 - Create archive (server) - 5 pts

Create gzip archive /root/d-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 12 - Create links (server) - 5 pts

Create /root/d-original, hard link /root/d-hard, and symlink /root/d-soft.

---

## Question 13 - Create systemd timer (server) - 4 pts

Create and enable examdtimer.timer that runs every 10 minutes.

---

## Question 14 - Create LVM mount (server) - 4 pts

Create VG vgd10 and LV datad mounted at /mnt/datad10.

---

## Question 15 - Restore SELinux context (server) - 4 pts

Create /var/www/html/d.html and restore its default SELinux context.

---

## Question 16 - Set SELinux boolean (server) - 4 pts

Persistently enable httpd_can_network_connect.

---

## Question 17 - Preserve journal (server) - 4 pts

Configure persistent systemd journal storage.

---

## Question 18 - Configure chrony (server) - 4 pts

Use server as the only chrony source and enable chronyd.

---

## Question 19 - Create cron job (server) - 4 pts

Create a cron job for userd10 that writes EXAM10 to /home/userd10/exam10.log every 15 minutes.

---

## Question 20 - Configure autofs (server) - 4 pts

Configure autofs so /remoted/projects mounts server:/exports/autofs/projects.

---

## Question 21 - Set default target (server) - 4 pts

Set the default target to multi-user.target without rebooting.

---

## Question 22 - Install local RPM package (server) - 4 pts

Install lsof and ensure tcpdump is removed.
