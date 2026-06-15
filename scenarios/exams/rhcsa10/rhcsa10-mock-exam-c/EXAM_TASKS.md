# RHCSA 10 Mock Exam C

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-c` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Web service and network focus: httpd service setup, custom service port, SELinux port labeling, firewalld, Flatpak, client storage, NFS, autofs, users, and scheduling.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Recover root password (client) - 5 pts

On client, recover root access and configure the client hostname. Set the root password to cinder9. Then set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure eth1 networking (client) - 5 pts

On client, configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Publish a web page /var/www/html/examc.html containing EXAMC and enable (client) - 5 pts

On client, publish a web page /var/www/html/examc.html containing EXAMC and enable httpd.

---

## Question 04 - Configure httpd to listen on TCP port 8102 and make the port usable by (client) - 5 pts

On client, configure httpd to listen on TCP port 8102 and make the port usable by the web service.

---

## Question 05 - Configure the server hostname and persistent IPv4 networking (server) - 5 pts

On server, configure the server hostname and persistent IPv4 networking:

- **Hostname:** serverc.exam10.lab
- **Hosts entry:** 192.168.122.62 clientc.exam10.lab
- **Eth1 Address:** 192.168.122.3/24
- **Gateway:** 192.168.122.1
- **DNS resolver:** 192.168.122.3

---

## Question 06 - Create /srv/serverc10 owned by root:serverc10 with mode 2770 (server) - 5 pts

On server, create /srv/serverc10 owned by root:serverc10 with mode 2770.

---

## Question 07 - Configure systemd timer (client) - 5 pts

On client, create and enable examctimer.timer that runs every 10 minutes.

---

## Question 08 - Create VG vgc10 and LV datac mounted at /mnt/datac10 (client) - 5 pts

On client, create VG vgc10 and LV datac mounted at /mnt/datac10.

---

## Question 09 - Allow TCP port 8102 permanently in firewalld and reload (client) - 4 pts

On client, allow TCP port 8102 permanently in firewalld and reload.

---

## Question 10 - Configure BaseOS and AppStream repositories (client + server) - 4 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 11 - Configure Flatpak remote examcflatpak (client) - 4 pts

On client, create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 12 - Install Flatpak application (client) - 4 pts

On client, install org.rhcsa.Tools from examcflatpak and leave it installed.

---

## Question 13 - Create user and group (client) - 4 pts

On client, create group teamc10, create user userc10, set password cinder9, and add the user to teamc10.

---

## Question 14 - Allow %teamc10 to run /usr/bin/systemctl without a password (client) - 4 pts

On client, allow %teamc10 to run /usr/bin/systemctl without a password.

---

## Question 15 - Configure sudo access (server) - 4 pts

On server, allow members of serverc10 to run /usr/bin/systemctl with sudo without a password.

---

## Question 16 - Create /var/www/html/c.html and restore its default SELinux context (client) - 4 pts

On client, create /var/www/html/c.html and restore its default SELinux context.

---

## Question 17 - Publish web content (server) - 4 pts

On server, publish /var/www/html/server-c.html containing RHCSA10-C and serve httpd on TCP port 8202.

---

## Question 18 - Enable persistent journal (server) - 4 pts

On server, enable persistent systemd journal storage.

---

## Question 19 - Configure systemd timer (server) - 4 pts

On server, create and enable serverctimer.timer so it appends SERVER-C to /var/log/serverctimer.log every 5 minutes.

---

## Question 20 - Configure NFS export and mount (client + server) - 4 pts

On server, export /exports/exam-c to the 192.168.122.0/24 network. On client, mount server:/exports/exam-c persistently at /mnt/cprojects.

---

## Question 21 - Add persistent host entry (client) - 4 pts

On client, add a hosts entry for serverc.exam10.lab and save the output of http://serverc.exam10.lab:8202/server-c.html to /root/server-c-web-check.txt.

---

## Question 22 - Route rsyslog messages (server) - 4 pts

On server, route local6 log messages to /var/log/server-c-local6.log and write a test message.

---

## Question 23 - Copy exam report to server (client + server) - 4 pts

On client, create /root/exam-c-report.txt containing REPORT-C and copy it to server:/root/exam-c-report.txt.
