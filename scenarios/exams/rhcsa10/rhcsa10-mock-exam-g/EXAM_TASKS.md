# RHCSA 10 Mock Exam G

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-g` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, software-scheduling-time, storage-lvm, users-sudo-ssh |

Recovery + NFS + Process focus: root password recovery, NFS mounts, process management, LVM, users/groups, and systemd timers on RHEL 10.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - (client) The root password has been lost. Boot into emergency mode and r (client) - 5 pts

(client) The root password has been lost. Boot into emergency mode and reset the root password to cinder9.

---

## Question 02 - (client) Set the hostname to clientg.exam10.lab. Add an entry to /etc/ho (client) - 5 pts

(client) Set the hostname to clientg.exam10.lab. Add an entry to /etc/hosts mapping 192.168.122.3 to serverg.exam10.lab.

---

## Question 03 - (client) Configure the connection "System eth1" with static IPv4: addres (client) - 5 pts

(client) Configure the connection "System eth1" with static IPv4: address 192.168.122.66/24, gateway 192.168.122.1, DNS 192.168.122.3. The connection must start automatically.

---

## Question 04 - (client) Add the kernel boot argument audit_backlog_limit=8192 to the de (client) - 5 pts

(client) Add the kernel boot argument audit_backlog_limit=8192 to the default GRUB entry so it persists across reboots.

---

## Question 05 - (client) Create enabled BaseOS and AppStream repository definitions usin (client) - 5 pts

(client) Create enabled BaseOS and AppStream repository definitions using http://server/repo/BaseOS/ and http://server/repo/AppStream/ with GPG checks disabled.

---

## Question 06 - (client) Add a system-level Flatpak remote named examgflatpak pointing t (client) - 5 pts

(client) Add a system-level Flatpak remote named examgflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled. Install org.rhcsa.Tools from that remote, verify it is listed, then remove it.

---

## Question 07 - (client) Mount the NFS export server:/exports/shareg at /mnt/shareg pers (client) - 5 pts

(client) Mount the NFS export server:/exports/shareg at /mnt/shareg persistently via /etc/fstab. The mount must survive reboots.

---

## Question 08 - (client) Create group devg10. Create users grant10 and hazel10 with devg (client) - 5 pts

(client) Create group devg10. Create users grant10 and hazel10 with devg10 as a supplementary group and passwords set to cinder9.

---

## Question 09 - (client) Create directory /srv/devg10 owned by root:devg10 with permissi (client) - 5 pts

(client) Create directory /srv/devg10 owned by root:devg10 with permissions 1770 (setgid and sticky bit, no world access).

---

## Question 10 - (client) Create user noaccess70 with no home directory and login shell / (client) - 5 pts

(client) Create user noaccess70 with no home directory and login shell /sbin/nologin.

---

## Question 11 - (client) Set password aging for grant10: maximum 35 days, minimum 5 days (client) - 5 pts

(client) Set password aging for grant10: maximum 35 days, minimum 5 days, warning 7 days. Add umask 0077 to /home/grant10/.bashrc.

---

## Question 12 - (client) Create user copy10 with UID 5010 and password cinder9 on the cl (client) - 5 pts

(client) Create user copy10 with UID 5010 and password cinder9 on the client. Also create user copy10 with the same UID 5010 and password cinder9 on the server.

---

## Question 13 - (client) As copy10, generate an SSH key pair (no passphrase) and distrib (client) - 4 pts

(client) As copy10, generate an SSH key pair (no passphrase) and distribute the public key to copy10@server. Then use scp to copy /etc/hostname from the server to /home/copy10/server-hostname on the client.

---

## Question 14 - (client) Schedule an at job for user hazel10 that runs: echo "exam-g tas (client) - 4 pts

(client) Schedule an at job for user hazel10 that runs: echo "exam-g task" >> /home/hazel10/at-result.txt.

---

## Question 15 - (server) Configure persistent systemd journal storage on the server (client) - 4 pts

(server) Configure persistent systemd journal storage on the server.

---

## Question 16 - (client) Run the command "sleep 600" in the background, then renice that (client) - 4 pts

(client) Run the command "sleep 600" in the background, then renice that process to priority 15.

---

## Question 17 - (client) Find all files under /opt/exam-g/find owned by user grant10 tha (client) - 4 pts

(client) Find all files under /opt/exam-g/find owned by user grant10 that were modified in the last day. Write the list to /root/grant-files (one path per line).

---

## Question 18 - (client) Extract all lines containing the string "data" from /usr/share/ (client) - 4 pts

(client) Extract all lines containing the string "data" from /usr/share/dict/words and write them to /root/g-data-lines.

---

## Question 19 - (client) Create a gzip-compressed tar archive /root/g-etc.tar.gz contain (client) - 4 pts

(client) Create a gzip-compressed tar archive /root/g-etc.tar.gz containing the entire /etc directory.

---

## Question 20 - (client) Create a systemd timer examgtimer.timer that triggers its compa (client) - 4 pts

(client) Create a systemd timer examgtimer.timer that triggers its companion service every 12 minutes. Enable the timer persistently.

---

## Question 21 - (client) Create a 500 MiB swap partition on /dev/sdb, format it as swap, (client) - 4 pts

(client) Create a 500 MiB swap partition on /dev/sdb, format it as swap, and enable it persistently via /etc/fstab.

---

## Question 22 - (client) Create physical volume on /dev/sdc, volume group vgg10, logical (client) - 4 pts

(client) Create physical volume on /dev/sdc, volume group vgg10, logical volume datag of 300 MiB, format as XFS, and mount persistently at /mnt/datag10.
