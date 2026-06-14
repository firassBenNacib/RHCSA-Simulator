# RHCSA 10 Mock Exam C

## Exam Solution
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

```bash
echo 'root:cinder9' | chpasswd
hostnamectl set-hostname clientc.exam10.lab
echo '192.168.122.3 serverc.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure eth1 networking (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.62/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Publish a web page /var/www/html/examc.html containing EXAMC and enable (client) - 5 pts

```bash
mkdir -p /var/www/html
echo EXAMC > /var/www/html/examc.html
restorecon -v /var/www/html/examc.html || true
systemctl enable --now httpd
```

---

## Question 04 - Configure httpd to listen on TCP port 8102 and make the port usable by (client) - 5 pts

```bash
cat > /etc/httpd/conf.d/examc-port.conf <<'EOF'
Listen 8102
EOF
semanage port -a -t http_port_t -p tcp 8102 2>/dev/null || semanage port -m -t http_port_t -p tcp 8102
systemctl restart httpd
```

---

## Question 05 - Set hostname (server) - 5 pts

```bash
# On server:
hostnamectl set-hostname serverc.exam10.lab
grep -Eq '^192\.168\.122\.62[[:space:]]+clientc\.exam10\.lab$' /etc/hosts || echo '192.168.122.62 clientc.exam10.lab' >> /etc/hosts
connection_name="System eth1"
nmcli -g NAME connection show "$connection_name" >/dev/null 2>&1 || connection_name="$(private_dev="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.122\./ {print $2; exit}')"; nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v private_dev="$private_dev" '$2 == private_dev {print $1; exit}')"
nmcli connection modify "$connection_name" ipv4.addresses 192.168.122.3/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "$connection_name"
```

---

## Question 06 - Create /srv/serverc10 owned by root:serverc10 with mode 2770 (server) - 5 pts

```bash
# On server:
getent group serverc10 >/dev/null || groupadd serverc10
mkdir -p /srv/serverc10
chown root:serverc10 /srv/serverc10
chmod 2770 /srv/serverc10
```

---

## Question 07 - Configure systemd timer (client) - 5 pts

```bash
cat > /usr/local/sbin/examctimer.sh <<'EOF'
#!/bin/bash
echo examctimer >> /var/log/examctimer.log
EOF
chmod +x /usr/local/sbin/examctimer.sh
cat > /etc/systemd/system/examctimer.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/examctimer.sh
EOF
cat > /etc/systemd/system/examctimer.timer <<'EOF'
[Timer]
OnCalendar=*:0/10
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now examctimer.timer
```

---

## Question 08 - Create VG vgc10 and LV datac mounted at /mnt/datac10 (client) - 5 pts

```bash
pvcreate /dev/sdb
vgcreate vgc10 /dev/sdb
lvcreate -L 384M -n datac vgc10
mkfs.xfs -f /dev/vgc10/datac
mkdir -p /mnt/datac10
echo '/dev/vgc10/datac /mnt/datac10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 09 - Allow TCP port 8102 permanently in firewalld and reload (client) - 4 pts

```bash
firewall-cmd --permanent --add-port=8102/tcp
firewall-cmd --reload
```

---

## Question 10 - Configure BaseOS and AppStream repositories (client + server) - 4 pts

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

## Question 11 - Configure Flatpak remote examcflatpak (client) - 4 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examcflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 12 - Install Flatpak application (client) - 4 pts

```bash
flatpak install --system -y examcflatpak org.rhcsa.Tools
flatpak list --system --app
```

---

## Question 13 - Create user and group (client) - 4 pts

```bash
groupadd teamc10
useradd -G teamc10 userc10
passwd userc10
# enter: cinder9
```

---

## Question 14 - Allow %teamc10 to run /usr/bin/systemctl without a password (client) - 4 pts

```bash
echo '%teamc10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamc10
chmod 440 /etc/sudoers.d/teamc10
```

---

## Question 15 - Configure sudo access (server) - 4 pts

```bash
# On server:
getent group serverc10 >/dev/null || groupadd serverc10
echo '%serverc10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/serverc10-systemctl
chmod 0440 /etc/sudoers.d/serverc10-systemctl
```

---

## Question 16 - Create /var/www/html/c.html and restore its default SELinux context (client) - 4 pts

```bash
echo c > /var/www/html/c.html
chcon -t user_tmp_t /var/www/html/c.html
restorecon -v /var/www/html/c.html
```

---

## Question 17 - Publish web content (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-C > /var/www/html/server-c.html
restorecon -v /var/www/html/server-c.html || true
cat > /etc/httpd/conf.d/exam-c-port.conf <<'EOF'
Listen 8202
EOF
semanage port -a -t http_port_t -p tcp 8202 2>/dev/null || semanage port -m -t http_port_t -p tcp 8202
firewall-cmd --permanent --add-port=8202/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 18 - Enable persistent journal (server) - 4 pts

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

## Question 19 - Configure systemd timer (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/serverctimer.sh <<'EOF'
#!/bin/bash
echo SERVER-C >> /var/log/serverctimer.log
EOF
chmod +x /usr/local/sbin/serverctimer.sh
cat > /etc/systemd/system/serverctimer.service <<'EOF'
[Unit]
Description=Server C timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serverctimer.sh
EOF
cat > /etc/systemd/system/serverctimer.timer <<'EOF'
[Unit]
Description=Run server C timer job

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serverctimer.timer
```

---

## Question 20 - Configure NFS export and mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-c
echo 'exam c export' > /exports/exam-c/README
cat > /etc/exports.d/exam-c-integrated.exports <<'EOF'
/exports/exam-c 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/cprojects
grep -Eq '^server:/exports/exam-c[[:space:]]+/mnt/cprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-c /mnt/cprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 21 - Save web service response (client) - 4 pts

```bash
grep -Eq '^192\.168\.122\.3[[:space:]]+serverc\.exam10\.lab$' /etc/hosts || echo '192.168.122.3 serverc.exam10.lab' >> /etc/hosts
curl -s http://serverc.exam10.lab:8202/server-c.html > /root/server-c-web-check.txt
```

---

## Question 22 - Route rsyslog messages (server) - 4 pts

```bash
# On server:
cat > /etc/rsyslog.d/server-c-local6.conf <<'EOF'
local6.* /var/log/server-c-local6.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local6.info 'server-c-local6'
sleep 1
```

---

## Question 23 - Copy exam report to server (client + server) - 4 pts

```bash
echo REPORT-C > /root/exam-c-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-c-report.txt root@server:/root/exam-c-report.txt
```
