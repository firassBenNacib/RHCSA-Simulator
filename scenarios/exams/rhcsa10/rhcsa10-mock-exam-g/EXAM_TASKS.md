# RHCSA 10 Mock Exam G

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-g` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, software-scheduling-time, storage-lvm, users-sudo-ssh |

Recovery + server administration focus: root password recovery, server-side login policy, process management, file search, systemd timers, swap, and LVM storage.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - The root password has been lost (client) - 5 pts

On client, the root password has been lost. Boot into emergency mode and reset the root password to cinder9.

---

## Question 02 - Recover root password (client) - 5 pts

On client, recover root access and configure the client hostname. Set the root password to cinder9. Then set the hostname to clientg.exam10.lab. Add an entry to /etc/hosts mapping 192.168.122.3 to serverg.exam10.lab.

---

## Question 03 - Configure the connection "System eth1" with static IPv4: address (client) - 5 pts

On client, configure the connection "System eth1" with static IPv4: address 192.168.122.66/24, gateway 192.168.122.1, DNS 192.168.122.3. The connection must start automatically.

---

## Question 04 - Persist kernel boot argument (client) - 5 pts

On client, add the kernel boot argument audit_backlog_limit=8192 to the default GRUB entry so it persists across reboots.

---

## Question 05 - Configure BaseOS and AppStream repositories (client + server) - 5 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 06 - Add a system-level Flatpak remote named examgflatpak (client) - 5 pts

On client, add a system-level Flatpak remote named examgflatpak.

- **Remote URL:** file:///opt/rhcsa/flatpak/repo
- **GPG verification:** disabled
- **Application state:** org.rhcsa.Tools must be installed.

---

## Question 07 - Set the server login message in /etc/motd to Authorized exam-g server (server) - 5 pts

On server, set the server login message in /etc/motd to Authorized exam-g server.

---

## Question 08 - Create group devg10 (client) - 5 pts

On client, create group devg10. Create users grant10 and hazel10 with devg10 as a supplementary group and passwords set to cinder9.

---

## Question 09 - Create directory /srv/devg10 owned by root:devg10 with permissions 1770 (client) - 4 pts

On client, create directory /srv/devg10 owned by root:devg10 with permissions 1770 (setgid and sticky bit, no world access).

---

## Question 10 - Create user noaccess70 with no home directory and login shell (client) - 4 pts

On client, create user noaccess70 with no home directory and login shell /sbin/nologin.

---

## Question 11 - Configure password aging (client) - 4 pts

On client, set password aging for grant10: maximum 35 days, minimum 5 days, warning 7 days. Add umask 0077 to /home/grant10/.bashrc.

---

## Question 12 - Create user copy10 with UID 5010 and password cinder9 (client + server) - 4 pts

On client, create user copy10 with UID 5010 and password cinder9. Also create user copy10 with the same UID 5010 and password cinder9 on the server.

---

## Question 13 - Configure SSH key authentication (client + server) - 4 pts

On client, as copy10, generate an SSH key pair (no passphrase) and distribute the public key to copy10@server. Then copy /etc/hostname from the server to /home/copy10/server-hostname.

---

## Question 14 - Schedule at job (client) - 4 pts

On client, schedule a queued at job for user hazel10. The job must run: echo "exam-g task" >> /home/hazel10/at-result.txt.

---

## Question 15 - Enable persistent journal (server) - 4 pts

On server, configure persistent systemd journal storage.

---

## Question 16 - Route rsyslog messages (server) - 4 pts

On server, route local5 log messages to /var/log/server-g-local5.log and write a test message.

---

## Question 17 - Create /srv/serverg10 owned by root:serverg10 with mode 2770 (server) - 4 pts

On server, create /srv/serverg10 owned by root:serverg10 with mode 2770.

---

## Question 18 - Create user and group (server) - 4 pts

On server, create group serverg10 and user srvg10 with password cinder9, then add the user to serverg10.

---

## Question 19 - Publish web content (server) - 4 pts

On server, publish /var/www/html/server-g.html containing RHCSA10-G and serve httpd on TCP port 8206.

---

## Question 20 - Configure systemd timer (server) - 4 pts

On server, create and enable servergtimer.timer so it appends SERVER-G to /var/log/servergtimer.log every 12 minutes.

---

## Question 21 - Configure persistent swap (client) - 4 pts

On client, create a 500 MiB swap partition on /dev/sdb, format it as swap, and enable it persistently via /etc/fstab.

---

## Question 22 - Configure LVM storage (client) - 4 pts

On client, create physical volume on /dev/sdc, volume group vgg10, logical volume datag of 300 MiB, format as XFS, and mount persistently at /mnt/datag10.

---

## Question 23 - Configure NFS export and mount (client + server) - 4 pts

On server, export /exports/exam-g to the 192.168.122.0/24 network. On client, mount server:/exports/exam-g persistently at /mnt/gprojects.
