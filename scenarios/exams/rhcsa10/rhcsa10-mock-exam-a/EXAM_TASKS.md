# RHCSA 10 Mock Exam A

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-a` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, networking-and-firewall, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A 22-task RHCSA 10 mock exam covering boot recovery, networking, Flatpak management, systemd timers, LVM storage, firewall, SELinux, shell scripting, and chrony time synchronisation across client and server.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Recover root access on client from the console (client) - 5 pts

On client, recover root access on client from the console.

Set the root password to: cinder9

---

## Question 02 - Set the hostname on client to clienta.exam10.lab (client) - 5 pts

On client, set the hostname on client to clienta.exam10.lab. Add a persistent hosts entry so that servera.exam10.lab resolves to 192.168.122.3.

---

## Question 03 - Configure the network connection for eth1 on client with the following s (client) - 5 pts

On client, configure the network connection for eth1 on client with the following settings:

- **IP Address:** 192.168.122.60/24
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Method:** manual
- **Autoconnect:** yes

---

## Question 04 - Configure the bootloader on client so every installed kernel boots with (client) - 5 pts

On client, configure the bootloader on client so every installed kernel boots with the kernel argument audit_backlog_limit=8192.

**Requirements**
- The change must persist across reboots.
- Do not rely on a one-time GRUB edit.

---

## Question 05 - Create enabled BaseOS and AppStream repository definitions with BaseOS a (client + server) - 5 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 06 - Configure the server hostname and persistent IPv4 networking (server) - 5 pts

On server, configure the server hostname and persistent IPv4 networking. Set hostname to servera.exam10.lab, map clienta.exam10.lab to 192.168.122.4, and configure eth1 with address 192.168.122.3/24, gateway 192.168.122.1, and DNS resolver 192.168.122.3.

---

## Question 07 - Add a system-level Flatpak remote named examaflatpak pointing to file:// (client) - 5 pts

On client, add a system-level Flatpak remote named examaflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled. Install org.rhcsa.Tools from that remote and leave it installed.

---

## Question 08 - Create group opsa10 on client (client) - 5 pts

On client, create group opsa10 on client. Create users anna10 and atlas10 with opsa10 as a supplementary group. Set passwords for both users to cinder9.

---

## Question 09 - Allow members of %opsa10 to run /usr/bin/systemctl without a password pr (client) - 4 pts

On client, allow members of %opsa10 to run /usr/bin/systemctl without a password prompt.

---

## Question 10 - Set the maximum password age for anna10 to 45 days and the password warn (client) - 4 pts

On client, set the maximum password age for anna10 to 45 days and the password warning period to 7 days.

---

## Question 11 - Create an executable script /usr/local/bin/a-who on client that accepts (client) - 4 pts

On client, create an executable script /usr/local/bin/a-who on client that accepts a username as its first argument and prints that user's primary group name.

---

## Question 12 - Write all usernames whose login shell ends with sh to /root/a-shell-user (client) - 4 pts

On client, write all usernames whose login shell ends with sh to /root/a-shell-users.txt, one per line, sorted alphabetically.

---

## Question 13 - Create /root/exam-a-report.txt containing REPORT-A and copy it to server (client + server) - 4 pts

On client, create /root/exam-a-report.txt containing REPORT-A and copy it to server:/root/exam-a-report.txt.

---

## Question 14 - Publish /var/www/html/server-a.html containing RHCSA10-A and serve httpd (server) - 4 pts

On server, publish /var/www/html/server-a.html containing RHCSA10-A and serve httpd on TCP port 8200.

---

## Question 15 - Create and enable serveratimer.timer so it appends SERVER-A to /var/log/ (server) - 4 pts

On server, create and enable serveratimer.timer so it appends SERVER-A to /var/log/serveratimer.log every 10 minutes.

---

## Question 16 - Create volume group vga10 from /dev/sdb (client) - 4 pts

On client, create volume group vga10 from /dev/sdb. Create logical volume dataa of at least 384 MiB inside vga10. Format it with XFS and mount it persistently at /mnt/dataa10.

---

## Question 17 - Create group servera10 and user srva10 with password cinder9, then add t (server) - 4 pts

On server, create group servera10 and user srva10 with password cinder9, then add the user to servera10.

---

## Question 18 - Create /srv/servera10 owned by root:servera10 with mode 2770 (server) - 4 pts

On server, create /srv/servera10 owned by root:servera10 with mode 2770.

---

## Question 19 - Persistently enable the SELinux boolean httpd_can_network_connect (server) - 4 pts

On server, persistently enable the SELinux boolean httpd_can_network_connect.

---

## Question 20 - Create the directory /srv/opsa10 owned by root:opsa10 with mode 3770 (se (client) - 4 pts

On client, create the directory /srv/opsa10 owned by root:opsa10 with mode 3770 (setgid + sticky + rwx for owner and group).

---

## Question 21 - Enable persistent systemd journal storage (server) - 4 pts

On server, enable persistent systemd journal storage.

---

## Question 22 - Make chronyd available as the lab time source (client + server) - 4 pts

On server, make chronyd available as the lab time source. On client, configure chronyd with server as its only time source.

---

## Question 23 - Export /exports/exam-a to the 192.168.122.0/24 network (client + server) - 4 pts

On server, export /exports/exam-a to the 192.168.122.0/24 network. On client, mount server:/exports/exam-a persistently at /mnt/aprojects.
