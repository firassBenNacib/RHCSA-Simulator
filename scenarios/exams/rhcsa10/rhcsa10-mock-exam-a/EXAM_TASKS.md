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

Recover root access on client from the console.

Set the root password to: cinder9

---

## Question 02 - Set the hostname on client to clienta.exam10.lab (client) - 5 pts

Set the hostname on client to clienta.exam10.lab. Add a persistent hosts entry so that servera.exam10.lab resolves to 192.168.122.3.

---

## Question 03 - Configure the network connection for eth1 on client with the following s (client) - 5 pts

Configure the network connection for eth1 on client with the following settings:

- **IP Address:** 192.168.122.60/24
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Method:** manual
- **Autoconnect:** yes

---

## Question 04 - Configure the bootloader on client so every installed kernel boots with (client) - 5 pts

Configure the bootloader on client so every installed kernel boots with the kernel argument audit_backlog_limit=8192.

**Requirements**
- The change must persist across reboots.
- Do not rely on a one-time GRUB edit.

---

## Question 05 - Create enabled BaseOS and AppStream repository definitions on client usi (client) - 5 pts

Create enabled BaseOS and AppStream repository definitions on client using:

- **BaseOS:** http://server/repo/BaseOS/
- **AppStream:** http://server/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 06 - create the same BaseOS and AppStream repository definitions: (server) - 5 pts

On server, create the same BaseOS and AppStream repository definitions:

- **BaseOS:** http://server/repo/BaseOS/
- **AppStream:** http://server/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 07 - add a system-level Flatpak remote named examaflatpak pointing to file:// (client) - 5 pts

On client, add a system-level Flatpak remote named examaflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled. Install org.rhcsa.Tools from that remote and leave it installed.

---

## Question 08 - Create group opsa10 on client (client) - 5 pts

Create group opsa10 on client. Create users anna10 and atlas10 with opsa10 as a supplementary group. Set passwords for both users to cinder9.

---

## Question 09 - allow members of %opsa10 to run /usr/bin/systemctl without a password pr (client) - 5 pts

On client, allow members of %opsa10 to run /usr/bin/systemctl without a password prompt. Use a sudoers drop-in file.

---

## Question 10 - set the maximum password age for anna10 to 45 days and the password warn (client) - 5 pts

On client, set the maximum password age for anna10 to 45 days and the password warning period to 7 days.

---

## Question 11 - Create an executable script /usr/local/bin/a-who on client that accepts (client) - 5 pts

Create an executable script /usr/local/bin/a-who on client that accepts a username as its first argument and prints that user's primary group name.

---

## Question 12 - write all usernames whose login shell ends with sh to /root/a-shell-user (client) - 5 pts

On client, write all usernames whose login shell ends with sh to /root/a-shell-users.txt, one per line, sorted alphabetically.

---

## Question 13 - create a gzip-compressed tar archive /root/a-etc.tar.gz containing /etc/ (client) - 4 pts

On client, create a gzip-compressed tar archive /root/a-etc.tar.gz containing /etc/hosts and /etc/fstab.

---

## Question 14 - create a regular file /root/a-original with some content (client) - 4 pts

On client, create a regular file /root/a-original with some content. Create a hard link /root/a-hard pointing to the same inode. Create a symbolic link /root/a-soft pointing to /root/a-original.

---

## Question 15 - create a systemd timer unit examatimer.timer that triggers an associated (client) - 4 pts

On client, create a systemd timer unit examatimer.timer that triggers an associated examatimer.service every 10 minutes. The service should run a one-shot script. Enable the timer so it starts at boot.

---

## Question 16 - create volume group vga10 using /dev/sdb (client) - 4 pts

On client, create volume group vga10 using /dev/sdb. Create logical volume dataa of at least 384 MiB inside vga10. Format it with XFS and mount it persistently at /mnt/dataa10.

---

## Question 17 - permanently allow TCP port 8100 through the firewall and reload firewall (client) - 4 pts

On client, permanently allow TCP port 8100 through the firewall and reload firewalld so the rule takes effect at runtime.

---

## Question 18 - create the file /var/www/html/a.html and restore its default SELinux con (client) - 4 pts

On client, create the file /var/www/html/a.html and restore its default SELinux context so the type is httpd_sys_content_t.

---

## Question 19 - persistently enable the SELinux boolean httpd_can_network_connect (client) - 4 pts

On client, persistently enable the SELinux boolean httpd_can_network_connect.

---

## Question 20 - create the directory /srv/opsa10 owned by root:opsa10 with mode 3770 (se (client) - 4 pts

On client, create the directory /srv/opsa10 owned by root:opsa10 with mode 3770 (setgid + sticky + rwx for owner and group).

---

## Question 21 - configure systemd-journald so logs are stored persistently across reboot (server) - 4 pts

On server, configure systemd-journald so logs are stored persistently across reboots and restart systemd-journald.

---

## Question 22 - configure the server (192.168.122.3) as the only chrony time source (client) - 4 pts

On client, configure the server (192.168.122.3) as the only chrony time source. Remove all other pool/server lines. Enable and start chronyd.
