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

## Question 01 - Set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168 (client) - 5 pts

On client, set hostname to clientc.exam10.lab and map serverc.exam10.lab to 192.168.122.3.

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.1 (client) - 5 pts

On client, configure System eth1 with IPv4 address 192.168.122.62/24, gateway 192.168.122.1, and DNS 192.168.122.3.

---

## Question 03 - Publish a web page /var/www/html/examc.html containing EXAMC and enable (client) - 5 pts

On client, publish a web page /var/www/html/examc.html containing EXAMC and enable httpd.

---

## Question 04 - Configure httpd to listen on TCP port 8102 and make the port usable by t (client) - 5 pts

On client, configure httpd to listen on TCP port 8102 and make the port usable by the web service.

---

## Question 05 - Set hostname to serverc.exam10.lab and map clientc.exam10.lab to 192.168 (server) - 5 pts

On server, set hostname to serverc.exam10.lab and map clientc.exam10.lab to 192.168.122.4.

---

## Question 06 - Create /srv/serverc10 owned by root:serverc10 with mode 2770 (server) - 5 pts

On server, create /srv/serverc10 owned by root:serverc10 with mode 2770.

---

## Question 07 - Create and enable examctimer.timer that runs every 10 minutes (client) - 5 pts

On client, create and enable examctimer.timer that runs every 10 minutes.

---

## Question 08 - Create VG vgc10 and LV datac mounted at /mnt/datac10 (client) - 5 pts

On client, create VG vgc10 and LV datac mounted at /mnt/datac10.

---

## Question 09 - Allow TCP port 8102 permanently in firewalld and reload (client) - 4 pts

On client, allow TCP port 8102 permanently in firewalld and reload.

---

## Question 10 - Create enabled BaseOS and AppStream repository definitions with BaseOS a (client + server) - 4 pts

On client and server, create enabled BaseOS and AppStream repository definitions with BaseOS at http://server/repo/BaseOS/ and AppStream at http://server/repo/AppStream/; disable GPG checks.

---

## Question 11 - Create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/ (client) - 4 pts

On client, create system Flatpak remote examcflatpak pointing to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Question 12 - Install org.rhcsa.Tools from examcflatpak and leave it installed (client) - 4 pts

On client, install org.rhcsa.Tools from examcflatpak and leave it installed.

---

## Question 13 - Create group teamc10, create user userc10, set password cinder9, and add (client) - 4 pts

On client, create group teamc10, create user userc10, set password cinder9, and add the user to teamc10.

---

## Question 14 - Allow %teamc10 to run /usr/bin/systemctl without a password (client) - 4 pts

On client, allow %teamc10 to run /usr/bin/systemctl without a password.

---

## Question 15 - Allow members of serverc10 to run /usr/bin/systemctl with sudo without a (server) - 4 pts

On server, allow members of serverc10 to run /usr/bin/systemctl with sudo without a password.

---

## Question 16 - Create /var/www/html/c.html and restore its default SELinux context (client) - 4 pts

On client, create /var/www/html/c.html and restore its default SELinux context.

---

## Question 17 - Publish /var/www/html/server-c.html containing RHCSA10-C and serve httpd (server) - 4 pts

On server, publish /var/www/html/server-c.html containing RHCSA10-C and serve httpd on TCP port 8202.

---

## Question 18 - Enable persistent systemd journal storage (server) - 4 pts

On server, enable persistent systemd journal storage.

---

## Question 19 - Create and enable serverctimer.timer so it appends SERVER-C to /var/log/ (server) - 4 pts

On server, create and enable serverctimer.timer so it appends SERVER-C to /var/log/serverctimer.log every 5 minutes.

---

## Question 20 - Export /exports/exam-c to the 192.168.122.0/24 network. on client, mount (client + server) - 4 pts

On server, export /exports/exam-c to the 192.168.122.0/24 network. On client, mount server:/exports/exam-c persistently at /mnt/cprojects.

---

## Question 21 - Add a hosts entry for serverc.exam10.lab and save the output of http://s (client + server) - 4 pts

On client, add a hosts entry for serverc.exam10.lab and save the output of http://serverc.exam10.lab:8202/server-c.html to /root/server-c-web-check.txt.

---

## Question 22 - Route local6 log messages to /var/log/server-c-local6.log and write a te (server) - 4 pts

On server, route local6 log messages to /var/log/server-c-local6.log and write a test message.

---

## Question 23 - Create /root/exam-c-report.txt containing REPORT-C and copy it to server (client + server) - 4 pts

On client, create /root/exam-c-report.txt containing REPORT-C and copy it to server:/root/exam-c-report.txt.
