# RHCSA 10 Mock Exam E

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-e` |
| Mode | Exam |
| Time limit | 180 minutes |
| Objectives | boot-and-recovery, essential-tools, filesystems-and-autofs, networking-and-firewall, processes-logs-tuning, selinux-and-default-perms, shell-scripting, software-management, software-scheduling-time, storage-lvm, users-sudo-ssh |

Storage and boot focus: labeled filesystem persistence, kernel arguments, LVM, NFS, documentation, package administration, users, scheduling, and logging.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Set hostname to cliente.exam10.lab and map servere.exam10.lab to 192.168 (client) - 5 pts

```bash
hostnamectl set-hostname cliente.exam10.lab
echo '192.168.122.3 servere.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.64/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.64/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Create enabled BaseOS and AppStream repository definitions with BaseOS a (client + server) - 5 pts

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

## Question 04 - Create a labeled XFS filesystem on /dev/sdc1 and mount it persistently a (client) - 5 pts

```bash
parted -s /dev/sdc -- mklabel gpt mkpart primary xfs 1MiB 513MiB
partprobe /dev/sdc || true
udevadm settle
mkfs.xfs -f -L EXAME10 /dev/sdc1
mkdir -p /mnt/exame-label
sed -i '\#/mnt/exame-label#d' /etc/fstab
echo 'LABEL=EXAME10 /mnt/exame-label xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 05 - Add audit_backlog_limit=8192 to all installed kernel entries (client) - 5 pts

```bash
grubby --update-kernel=ALL --args='audit_backlog_limit=8192'
grubby --info=ALL | grep audit_backlog_limit
```

---

## Question 06 - Create group teame10, create user usere10, set password cinder9, and add (client) - 5 pts

```bash
groupadd teame10
useradd -G teame10 usere10
passwd usere10
# enter: cinder9
```

---

## Question 07 - Create group servere10 and user srve10 with password cinder9, then add t (server) - 5 pts

```bash
# On server:
getent group servere10 >/dev/null || groupadd servere10
id srve10 >/dev/null 2>&1 || useradd srve10
gpasswd -a srve10 servere10
echo 'srve10:cinder9' | chpasswd
```

---

## Question 08 - Allow members of servere10 to run /usr/bin/systemctl with sudo without a (server) - 5 pts

```bash
# On server:
getent group servere10 >/dev/null || groupadd servere10
echo '%servere10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/servere10-systemctl
chmod 0440 /etc/sudoers.d/servere10-systemctl
```

---

## Question 09 - Create /usr/local/bin/e-who that prints the primary group for the suppli (client) - 4 pts

```bash
cat > /usr/local/bin/e-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/e-who
```

---

## Question 10 - Write users whose shell ends with sh to /root/e-shell-users.txt (client) - 4 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/e-shell-users.txt
```

---

## Question 11 - Create gzip archive /root/e-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 4 pts

```bash
tar -czf /root/e-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/e-etc.tar.gz
```

---

## Question 12 - Create /root/e-original, hard link /root/e-hard, and symlink /root/e-sof (client) - 4 pts

```bash
echo link > /root/e-original
ln /root/e-original /root/e-hard
ln -s /root/e-original /root/e-soft
```

---

## Question 13 - Create and enable serveretimer.timer so it appends SERVER-E to /var/log/ (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/serveretimer.sh <<'EOF'
#!/bin/bash
echo SERVER-E >> /var/log/serveretimer.log
EOF
chmod +x /usr/local/sbin/serveretimer.sh
cat > /etc/systemd/system/serveretimer.service <<'EOF'
[Unit]
Description=Server E timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serveretimer.sh
EOF
cat > /etc/systemd/system/serveretimer.timer <<'EOF'
[Unit]
Description=Run server E timer job

[Timer]
OnCalendar=*:0/10
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serveretimer.timer
```

---

## Question 14 - Create VG vge10 and LV datae mounted at /mnt/datae10 (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vge10 /dev/sdb
lvcreate -L 384M -n datae vge10
mkfs.xfs -f /dev/vge10/datae
mkdir -p /mnt/datae10
echo '/dev/vge10/datae /mnt/datae10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 15 - Publish /var/www/html/server-e.html containing RHCSA10-E and serve httpd (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-E > /var/www/html/server-e.html
restorecon -v /var/www/html/server-e.html || true
cat > /etc/httpd/conf.d/exam-e-port.conf <<'EOF'
Listen 8204
EOF
semanage port -a -t http_port_t -p tcp 8204 2>/dev/null || semanage port -m -t http_port_t -p tcp 8204
firewall-cmd --permanent --add-port=8204/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 16 - Create /srv/servere10 owned by root:servere10 with mode 2770 (server) - 4 pts

```bash
# On server:
getent group servere10 >/dev/null || groupadd servere10
mkdir -p /srv/servere10
chown root:servere10 /srv/servere10
chmod 2770 /srv/servere10
```

---

## Question 17 - Activate the throughput-performance tuned profile (client) - 4 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 18 - Route local5 log messages to /var/log/server-e-local5.log and write a te (server) - 4 pts

```bash
# On server:
cat > /etc/rsyslog.d/server-e-local5.conf <<'EOF'
local5.* /var/log/server-e-local5.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local5.info 'server-e-local5'
sleep 1
```

---

## Question 19 - Export /exports/exam-e to the 192.168.122.0/24 network. on client, mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-e
echo 'exam e export' > /exports/exam-e/README
cat > /etc/exports.d/exam-e-integrated.exports <<'EOF'
/exports/exam-e 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/eprojects
grep -Eq '^server:/exports/exam-e[[:space:]]+/mnt/eprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-e /mnt/eprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 20 - Create /root/exam-e-report.txt containing REPORT-E and copy it to server (client + server) - 4 pts

```bash
echo REPORT-E > /root/exam-e-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-e-report.txt root@server:/root/exam-e-report.txt
```

---

## Question 21 - Install lsof and ensure tcpdump is removed (client) - 4 pts

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

## Question 22 - Enable persistent systemd journal storage (server) - 4 pts

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

## Question 23 - Add a hosts entry for servere.exam10.lab and save the output of http://s (client + server) - 4 pts

```bash
grep -Eq '^192\.168\.122\.3[[:space:]]+servere\.exam10\.lab$' /etc/hosts || echo '192.168.122.3 servere.exam10.lab' >> /etc/hosts
curl -s http://servere.exam10.lab:8204/server-e.html > /root/server-e-web-check.txt
```
