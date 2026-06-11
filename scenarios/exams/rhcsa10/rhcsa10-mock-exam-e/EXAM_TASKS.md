# RHCSA 10 Mock Exam E

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-e` |
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

## Question 01 - set hostname to cliente.exam10.lab and map servere.exam10.lab to 192.168 (client) - 5 pts

On client, set hostname to cliente.exam10.lab and map servere.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.64/24, gateway 192.1 (client) - 5 pts

Configure System eth1 with IPv4 address 192.168.122.64/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Create enabled BaseOS and AppStream repository definitions using http:// (client) - 5 pts

Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 04 - Create system Flatpak remote exameflatpak pointing to file:///opt/rhcsa/ (client) - 5 pts

Create system Flatpak remote exameflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 05 - Ensure org.rhcsa.Tools is not installed after configuring exameflatpak (client) - 5 pts

Ensure org.rhcsa.Tools is not installed after configuring exameflatpak.

---

## Question 06 - Create group teame10, create user usere10, set password cinder9, and add (client) - 5 pts

Create group teame10, create user usere10, set password cinder9, and add the user to teame10.

---

## Question 07 - Allow %teame10 to run /usr/bin/systemctl without a password by using a s (client) - 5 pts

Allow %teame10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 08 - Set maximum password age for usere10 to 49 days and warning period to 7 (client) - 5 pts

Set maximum password age for usere10 to 49 days and warning period to 7 days.

---

## Question 09 - Create /usr/local/bin/e-who that prints the primary group for the suppli (client) - 5 pts

Create /usr/local/bin/e-who that prints the primary group for the supplied user argument.

---

## Question 10 - Write users whose shell ends with sh to /root/e-shell-users.txt (client) - 5 pts

Write users whose shell ends with sh to /root/e-shell-users.txt.

---

## Question 11 - Create gzip archive /root/e-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 5 pts

Create gzip archive /root/e-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 12 - Create /root/e-original, hard link /root/e-hard, and symlink /root/e-sof (client) - 5 pts

Create /root/e-original, hard link /root/e-hard, and symlink /root/e-soft.

---

## Question 13 - Create and enable exametimer.timer that runs every 10 minutes (client) - 4 pts

Create and enable exametimer.timer that runs every 10 minutes.

---

## Question 14 - Create VG vge10 and LV datae mounted at /mnt/datae10 (client) - 4 pts

Create VG vge10 and LV datae mounted at /mnt/datae10.

---

## Question 15 - Allow TCP port 8104 permanently in firewalld and reload (client) - 4 pts

Allow TCP port 8104 permanently in firewalld and reload.

---

## Question 16 - Create /var/www/html/e.html and restore its default SELinux context (client) - 4 pts

Create /var/www/html/e.html and restore its default SELinux context.

---

## Question 17 - Activate the throughput-performance tuned profile (client) - 4 pts

Activate the throughput-performance tuned profile.

---

## Question 18 - Create a cron job for usere10 that writes EXAM10 to /home/usere10/exam10 (client) - 4 pts

Create a cron job for usere10 that writes EXAM10 to /home/usere10/exam10.log every 15 minutes.

---

## Question 19 - mount server:/exports/direct at /mnt/edirect persistently (client) - 4 pts

On client, mount server:/exports/direct at /mnt/edirect persistently.

---

## Question 20 - Set the default target to multi-user.target without rebooting (client) - 4 pts

Set the default target to multi-user.target without rebooting.

---

## Question 21 - Install lsof and ensure tcpdump is removed (client) - 4 pts

Install lsof and ensure tcpdump is removed.

---

## Question 22 - Configure persistent systemd journal storage (client) - 4 pts

Configure persistent systemd journal storage.
