# RHCSA 10 Mock Exam C

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-c` |
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

## Question 01 - Set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168 (server) - 5 pts

Set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.1 (server) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create /usr/local/bin/c-who that prints the primary group for the suppli (server) - 5 pts

Create /usr/local/bin/c-who that prints the primary group for the supplied user argument.

---

## Question 04 - Write users whose shell ends with sh to /root/c-shell-users.txt (server) - 5 pts

Write users whose shell ends with sh to /root/c-shell-users.txt.

---

## Question 05 - Create gzip archive /root/c-etc.tar.gz containing /etc/hosts and /etc/fs (server) - 5 pts

Create gzip archive /root/c-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 06 - Create /root/c-original, hard link /root/c-hard, and symlink /root/c-sof (server) - 5 pts

Create /root/c-original, hard link /root/c-hard, and symlink /root/c-soft.

---

## Question 07 - Create and enable examctimer.timer that runs every 10 minutes (server) - 4 pts

Create and enable examctimer.timer that runs every 10 minutes.

---

## Question 08 - Create VG vgc10 and LV datac mounted at /mnt/datac10 (server) - 4 pts

Create VG vgc10 and LV datac mounted at /mnt/datac10.

---

## Question 09 - Allow TCP port 8102 permanently in firewalld and reload (server) - 4 pts

Allow TCP port 8102 permanently in firewalld and reload.

---

## Question 10 - Create enabled BaseOS and AppStream repository definitions using http:// (server) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 11 - Create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/ (server) - 5 pts

Create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 12 - Install org.rhcsa.Tools from examcflatpak and leave it installed (server) - 5 pts

Install org.rhcsa.Tools from examcflatpak and leave it installed.

---

## Question 13 - Create group teamc10, create user userc10, set password cinder9, and add (server) - 5 pts

Create group teamc10, create user userc10, set password cinder9, and add the user to teamc10.

---

## Question 14 - Allow %teamc10 to run /usr/bin/systemctl without a password by using a s (server) - 5 pts

Allow %teamc10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 15 - Set maximum password age for userc10 to 47 days and warning period to 7 (server) - 5 pts

Set maximum password age for userc10 to 47 days and warning period to 7 days.

---

## Question 16 - Create /var/www/html/c.html and restore its default SELinux context (server) - 4 pts

Create /var/www/html/c.html and restore its default SELinux context.

---

## Question 17 - Activate the throughput-performance tuned profile (server) - 4 pts

Activate the throughput-performance tuned profile.

---

## Question 18 - Configure persistent systemd journal storage (server) - 4 pts

Configure persistent systemd journal storage.

---

## Question 19 - Create a cron job for userc10 that writes EXAM10 to /home/userc10/exam10 (server) - 4 pts

Create a cron job for userc10 that writes EXAM10 to /home/userc10/exam10.log every 15 minutes.

---

## Question 20 - Mount server:/exports/direct at /mnt/cdirect persistently (server) - 4 pts

- **Mount server:** /exports/direct at /mnt/cdirect persistently.

---

## Question 21 - Configure autofs so /remotec/projects mounts server:/exports/autofs/proj (server) - 4 pts

Configure autofs so /remotec/projects mounts server:/exports/autofs/projects.

---

## Question 22 - Set the default target to multi-user.target without rebooting (server) - 4 pts

Set the default target to multi-user.target without rebooting.
