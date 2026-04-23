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
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Configure hostname and hosts entry (server) - 5 pts

Set hostname to clientf.exam10.lab and map serverf.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure IPv4 profile (server) - 5 pts

Set System eth1 to 192.168.122.65/24 with gateway 192.168.122.1 and DNS 192.168.122.3.

---

## Question 03 - Configure RPM repositories (server) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 04 - Configure Flatpak remote (server) - 5 pts

Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 05 - Install and remove Flatpak app (server) - 5 pts

Install org.rhcsa.Tools from examfflatpak, then remove it after verification.

---

## Question 06 - Create user and group (server) - 5 pts

Create group teamf10, create user userf10, set password cinder9, and add the user to teamf10.

---

## Question 07 - Delegate sudo access (server) - 5 pts

Allow %teamf10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 08 - Set password aging (server) - 5 pts

Set maximum password age for userf10 to 50 days and warning period to 7 days.

---

## Question 09 - Create argument script (server) - 5 pts

Create /usr/local/bin/f-who that prints the primary group for the supplied user argument.

---

## Question 10 - Filter shell users (server) - 5 pts

Write users whose shell ends with sh to /root/f-shell-users.txt.

---

## Question 11 - Create archive (server) - 5 pts

Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 12 - Create links (server) - 5 pts

Create /root/f-original, hard link /root/f-hard, and symlink /root/f-soft.

---

## Question 13 - Create systemd timer (server) - 4 pts

Create and enable examftimer.timer that runs every 10 minutes.

---

## Question 14 - Create LVM mount (server) - 4 pts

Create VG vgf10 and LV dataf mounted at /mnt/dataf10.

---

## Question 15 - Set SELinux boolean (server) - 4 pts

Persistently enable httpd_can_network_connect.

---

## Question 16 - Restore SELinux context (server) - 4 pts

Create /var/www/html/f.html and restore its default SELinux context.

---

## Question 17 - Set tuned profile (server) - 4 pts

Activate the throughput-performance tuned profile.

---

## Question 18 - Preserve journal (server) - 4 pts

Configure persistent systemd journal storage.

---

## Question 19 - Create cron job (server) - 4 pts

Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10.log every 15 minutes.

---

## Question 20 - Set default target (server) - 4 pts

Set the default target to multi-user.target without rebooting.

---

## Question 21 - Install local RPM package (server) - 4 pts

Install lsof and ensure tcpdump is removed.

---

## Question 22 - Configure firewalld (server) - 4 pts

Allow TCP port 8105 permanently in firewalld and reload.
