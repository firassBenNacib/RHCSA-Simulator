# RHCSA 10 Mock Exam B

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-b` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Software and permissions focus: offline package installation, shared directories, default ACLs, fixed user identity, storage, NFS, journald, and systemd administration.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Recover root password (client) - 5 pts

On client, recover root access and configure the client hostname. Set the root password to cinder9. Then set hostname to clientb.exam10.lab and map serverb.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure eth1 networking (client) - 5 pts

On client, configure System eth1 with IPv4 address 192.168.122.61/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Configure BaseOS and AppStream repositories (client + server) - 5 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 04 - Install the tree package from the configured offline repositories (client) - 5 pts

On client, install the tree package from the configured offline repositories.

---

## Question 05 - Create /srv/teamb10 as a shared directory for group teamb10 (client) - 5 pts

On client, create /srv/teamb10 as a shared directory for group teamb10.

---

## Question 06 - Create user and group (client) - 5 pts

On client, create group teamb10, create user userb10, set password cinder9, and add the user to teamb10.

---

## Question 07 - Create user auditorb10 with UID 6102 and shell /sbin/nologin (client) - 5 pts

On client, create user auditorb10 with UID 6102 and shell /sbin/nologin.

---

## Question 08 - Configure password aging (client) - 5 pts

On client, set maximum password age for userb10 to 46 days and warning period to 7 days.

---

## Question 09 - Create user lookup script (client) - 5 pts

On client, create /usr/local/bin/b-who that prints the primary group for the supplied user argument.

---

## Question 10 - Copy exam report to server (client + server) - 5 pts

On client, create /root/exam-b-report.txt containing REPORT-B and copy it to server:/root/exam-b-report.txt.

---

## Question 11 - Create gzip archive (client) - 5 pts

On client, create gzip archive /root/b-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 12 - Create /root/b-original, hard link /root/b-hard, and symlink (client) - 5 pts

On client, create /root/b-original, hard link /root/b-hard, and symlink /root/b-soft.

---

## Question 13 - Configure systemd timer (server) - 4 pts

On server, create and enable serverbtimer.timer so it appends SERVER-B to /var/log/serverbtimer.log every 10 minutes.

---

## Question 14 - Configure LVM storage (client) - 4 pts

On client, create physical volume on /dev/sdb, volume group vgb10, logical volume datab of 384 MiB, format it with XFS, and mount it persistently at /mnt/datab10.

---

## Question 15 - Publish web content (server) - 4 pts

On server, publish /var/www/html/server-b.html containing RHCSA10-B and serve httpd on TCP port 8201.

---

## Question 16 - Create user and group (server) - 4 pts

On server, create group serverb10 and user srvb10 with password cinder9, then add the user to serverb10.

---

## Question 17 - Configure sudo access (server) - 4 pts

On server, allow members of serverb10 to run /usr/bin/systemctl with sudo without a password.

---

## Question 18 - Enable persistent journal (server) - 4 pts

On server, enable persistent systemd journal storage.

---

## Question 19 - Route rsyslog messages (server) - 4 pts

On server, route local5 log messages to /var/log/server-b-local5.log and write a test message.

---

## Question 20 - Configure NFS export and mount (client + server) - 4 pts

On server, export /exports/exam-b to the 192.168.122.0/24 network. On client, mount server:/exports/exam-b persistently at /mnt/bprojects.

---

## Question 21 - Set the default boot target to multi-user.target without rebooting (server) - 4 pts

On server, set the default boot target to multi-user.target without rebooting.

---

## Question 22 - Install lsof and ensure tcpdump is removed (client) - 4 pts

On client, install lsof and ensure tcpdump is removed.
