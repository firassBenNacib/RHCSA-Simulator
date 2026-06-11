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

## Question 01 - set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168 (client) - 5 pts

On client, set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168.122.3.

---

## Question 02 - configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.1 (client) - 5 pts

On client, configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - create /usr/local/bin/c-who that prints the primary group for the suppli (client) - 5 pts

On client, create /usr/local/bin/c-who that prints the primary group for the supplied user argument.

---

## Question 04 - write users whose shell ends with sh to /root/c-shell-users.txt (client) - 5 pts

On client, write users whose shell ends with sh to /root/c-shell-users.txt.

---

## Question 05 - create gzip archive /root/c-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 5 pts

On client, create gzip archive /root/c-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 06 - create /root/c-original, hard link /root/c-hard, and symlink /root/c-sof (client) - 5 pts

On client, create /root/c-original, hard link /root/c-hard, and symlink /root/c-soft.

---

## Question 07 - create and enable examctimer.timer that runs every 10 minutes (client) - 4 pts

On client, create and enable examctimer.timer that runs every 10 minutes.

---

## Question 08 - create VG vgc10 and LV datac mounted at /mnt/datac10 (client) - 4 pts

On client, create VG vgc10 and LV datac mounted at /mnt/datac10.

---

## Question 09 - allow TCP port 8102 permanently in firewalld and reload (client) - 4 pts

On client, allow TCP port 8102 permanently in firewalld and reload.

---

## Question 10 - create enabled BaseOS and AppStream repository definitions using http:// (client) - 5 pts

On client, create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 11 - create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/ (client) - 5 pts

On client, create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 12 - install org.rhcsa.Tools from examcflatpak and leave it installed (client) - 5 pts

On client, install org.rhcsa.Tools from examcflatpak and leave it installed.

---

## Question 13 - create group teamc10, create user userc10, set password cinder9, and add (client) - 5 pts

On client, create group teamc10, create user userc10, set password cinder9, and add the user to teamc10.

---

## Question 14 - allow %teamc10 to run /usr/bin/systemctl without a password by using a s (client) - 5 pts

On client, allow %teamc10 to run /usr/bin/systemctl without a password by using a sudoers drop-in.

---

## Question 15 - set maximum password age for userc10 to 47 days and warning period to 7 (client) - 5 pts

On client, set maximum password age for userc10 to 47 days and warning period to 7 days.

---

## Question 16 - create /var/www/html/c.html and restore its default SELinux context (client) - 4 pts

On client, create /var/www/html/c.html and restore its default SELinux context.

---

## Question 17 - activate the throughput-performance tuned profile (client) - 4 pts

On client, activate the throughput-performance tuned profile.

---

## Question 18 - configure persistent systemd journal storage (client) - 4 pts

On client, configure persistent systemd journal storage.

---

## Question 19 - create a cron job for userc10 that writes EXAM10 to /home/userc10/exam10 (client) - 4 pts

On client, create a cron job for userc10 that writes EXAM10 to /home/userc10/exam10.log every 15 minutes.

---

## Question 20 - mount server:/exports/direct at /mnt/cdirect persistently (client) - 4 pts

On client, mount server:/exports/direct at /mnt/cdirect persistently.

---

## Question 21 - configure autofs so /remotec/projects mounts server:/exports/autofs/proj (client) - 4 pts

On client, configure autofs so /remotec/projects mounts server:/exports/autofs/projects.

---

## Question 22 - set the default target to multi-user.target without rebooting (client) - 4 pts

On client, set the default target to multi-user.target without rebooting.
