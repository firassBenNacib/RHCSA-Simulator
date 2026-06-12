# RHCSA 10 Mock Exam H

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-h` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

A RHCSA 10 mock exam focused on RHEL 10 administration, Flatpak, systemd timers, storage, networking, users, security, and services.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - set hostname to clienth.exam10.lab and map serverh.exam10.lab to 192.168 (client) - 5 pts

```bash
hostnamectl set-hostname clienth.exam10.lab
echo '192.168.122.3 serverh.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.67/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.67/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - set hostname to serverh.exam10.lab and map clienth.exam10.lab to 192.168 (server) - 5 pts

```bash
# On server:
hostnamectl set-hostname serverh.exam10.lab
grep -Eq '^192\.168\.122\.4[[:space:]]+clienth\.exam10\.lab$' /etc/hosts || echo '192.168.122.4 clienth.exam10.lab' >> /etc/hosts
```

---

## Question 04 - create /root/exam-h-report.txt containing REPORT-H and copy it to server (client) - 5 pts

```bash
echo REPORT-H > /root/exam-h-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-h-report.txt root@server:/root/exam-h-report.txt
```

---

## Question 05 - create and enable serverhtimer.timer so it appends SERVER-H to /var/log/ (server) - 5 pts

```bash
# On server:
cat > /usr/local/sbin/serverhtimer.sh <<'EOF'
#!/bin/bash
echo SERVER-H >> /var/log/serverhtimer.log
EOF
chmod +x /usr/local/sbin/serverhtimer.sh
cat > /etc/systemd/system/serverhtimer.service <<'EOF'
[Unit]
Description=Server H timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serverhtimer.sh
EOF
cat > /etc/systemd/system/serverhtimer.timer <<'EOF'
[Unit]
Description=Run server H timer job

[Timer]
OnCalendar=*:/10
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serverhtimer.timer
```

---

## Question 06 - Create group teamh10, create user userh10, set password cinder9, and add (client) - 5 pts

```bash
groupadd teamh10
useradd -G teamh10 userh10
passwd userh10
# enter: cinder9
```

---

## Question 07 - Set maximum password age for userh10 to 52 days and warning period to 7 (client) - 5 pts

```bash
chage -M 52 -W 7 userh10
```

---

## Question 08 - Persistently enable httpd_can_network_connect (client) - 5 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Question 09 - Write users whose shell ends with sh to /root/h-shell-users.txt (client) - 5 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/h-shell-users.txt
```

---

## Question 10 - configure persistent systemd journal storage (server) - 5 pts

```bash
# On server:
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
journalctl --flush
```

---

## Question 11 - create /srv/serverh10 owned by root:serverh10 with mode 2770 (server) - 5 pts

```bash
# On server:
getent group serverh10 >/dev/null || groupadd serverh10
mkdir -p /srv/serverh10
chown root:serverh10 /srv/serverh10
chmod 2770 /srv/serverh10
```

---

## Question 12 - Create a cron job for userh10 that writes EXAM10 to /home/userh10/exam10 (client) - 5 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userh10/exam10.log' | crontab -u userh10 -
```

---

## Question 13 - Create VG vgh10 and LV datah mounted at /mnt/datah10 (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vgh10 /dev/sdb
lvcreate -L 384M -n datah vgh10
mkfs.xfs -f /dev/vgh10/datah
mkdir -p /mnt/datah10
echo '/dev/vgh10/datah /mnt/datah10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 14 - Set the default target to multi-user.target without rebooting (client) - 4 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```

---

## Question 15 - route local6 log messages to /var/log/examh-local6.log and write a test (server) - 4 pts

```bash
# On server:
cat > /etc/rsyslog.d/examh-local6.conf <<'EOF'
local6.* /var/log/examh-local6.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local6.info 'exam-h local6'
sleep 1
```

---

## Question 16 - Install lsof and ensure tcpdump is removed (client) - 4 pts

```bash
cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'
[rhcsa10-exam-baseos]
name=RHCSA10 Exam BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa10-exam-appstream]
name=RHCSA10 Exam AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
dnf install -y lsof
dnf remove -y tcpdump
```

---

## Question 17 - make chronyd available as the lab time source. On client, configure chro (client + server) - 4 pts

```bash
# On server:
systemctl enable --now chronyd
firewall-cmd --permanent --add-service=ntp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
# On client:
cat > /etc/chrony.conf <<'EOF'
server server iburst
makestep 1.0 3
EOF
systemctl enable --now chronyd
```

---

## Question 18 - publish /var/www/html/server-h.html containing RHCSA10-H and serve httpd (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-H > /var/www/html/server-h.html
restorecon -v /var/www/html/server-h.html || true
cat > /etc/httpd/conf.d/exam-h-port.conf <<'EOF'
Listen 8207
EOF
semanage port -a -t http_port_t -p tcp 8207 2>/dev/null || semanage port -m -t http_port_t -p tcp 8207
firewall-cmd --permanent --add-port=8207/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 19 - On client and server, create enabled BaseOS and AppStream repository def (client + server) - 4 pts

```bash
cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'
[rhcsa10-exam-baseos]
name=RHCSA10 Exam BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa10-exam-appstream]
name=RHCSA10 Exam AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
# On server:
cat > /etc/yum.repos.d/rhcsa10-exam.repo <<'EOF'
[rhcsa10-exam-baseos]
name=RHCSA10 Exam BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa10-exam-appstream]
name=RHCSA10 Exam AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 20 - Allow %teamh10 to run /usr/bin/systemctl without a password (client) - 4 pts

```bash
echo '%teamh10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamh10
chmod 440 /etc/sudoers.d/teamh10
```

---

## Question 21 - allow members of serverh10 to run /usr/bin/systemctl with sudo without a (server) - 4 pts

```bash
# On server:
getent group serverh10 >/dev/null || groupadd serverh10
echo '%serverh10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/serverh10-systemctl
chmod 0440 /etc/sudoers.d/serverh10-systemctl
```

---

## Question 22 - Create gzip archive /root/h-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 4 pts

```bash
tar -czf /root/h-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/h-etc.tar.gz
```
