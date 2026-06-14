# RHCSA 10 Mock Exam F

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-mock-exam-f` |
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

## Question 01 - Recover root access and configure the client hostname (client) - 5 pts

```bash
echo 'root:cinder9' | chpasswd
hostnamectl set-hostname clientf.exam10.lab
echo '192.168.122.3 serverf.exam10.lab' >> /etc/hosts
```

---

## Question 02 - Configure System eth1 with IPv4 address 192.168.122.65/24, gateway 192.1 (client) - 5 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.65/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 03 - Create /root/exam-f-report.txt containing REPORT-F and copy it to server (client + server) - 5 pts

```bash
echo REPORT-F > /root/exam-f-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-f-report.txt root@server:/root/exam-f-report.txt
```

---

## Question 04 - Create a 500 MiB swap partition on /dev/sdc and make it active and persi (client) - 5 pts

```bash
parted -s /dev/sdc -- mklabel gpt mkpart primary linux-swap 1MiB 501MiB
partprobe /dev/sdc || true
udevadm settle
mkswap /dev/sdc1
uuid=$(blkid -s UUID -o value /dev/sdc1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
swapon /dev/sdc1
```

---

## Question 05 - Activate the throughput-performance tuned profile (client) - 5 pts

```bash
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Question 06 - Create system Flatpak remote examfflatpak pointing to file:///opt/rhcsa/ (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examfflatpak file:///opt/rhcsa/flatpak/repo
```

---

## Question 07 - Ensure org.rhcsa.Tools is not installed after configuring examfflatpak (client) - 5 pts

```bash
flatpak uninstall --system -y org.rhcsa.Tools >/dev/null 2>&1 || true
```

---

## Question 08 - Enable persistent systemd journal storage (server) - 5 pts

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

## Question 09 - Allow %teamf10 to run /usr/bin/systemctl without a password (client) - 5 pts

```bash
echo '%teamf10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/teamf10
chmod 440 /etc/sudoers.d/teamf10
```

---

## Question 10 - Create group teamf10, create user userf10, set password cinder9, and add (client) - 5 pts

```bash
groupadd teamf10
useradd -G teamf10 userf10
passwd userf10
# enter: cinder9
```

---

## Question 11 - Create a cron job for userf10 that writes EXAM10 to /home/userf10/exam10 (client) - 5 pts

```bash
echo '*/15 * * * * echo EXAM10 >> /home/userf10/exam10.log' | crontab -u userf10 -
```

---

## Question 12 - Create /usr/local/bin/f-who that prints the primary group for the suppli (client) - 5 pts

```bash
cat > /usr/local/bin/f-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/f-who
```

---

## Question 13 - Set the default boot target to multi-user.target without rebooting (server) - 4 pts

```bash
# On server:
systemctl set-default multi-user.target
systemctl get-default
```

---

## Question 14 - Create gzip archive /root/f-etc.tar.gz containing /etc/hosts and /etc/fs (client) - 4 pts

```bash
tar -czf /root/f-etc.tar.gz /etc/hosts /etc/fstab
tar -tzf /root/f-etc.tar.gz
```

---

## Question 15 - Export /exports/exam-f to the 192.168.122.0/24 network (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-f
echo 'exam f export' > /exports/exam-f/README
cat > /etc/exports.d/exam-f-integrated.exports <<'EOF'
/exports/exam-f 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/fprojects
grep -Eq '^server:/exports/exam-f[[:space:]]+/mnt/fprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-f /mnt/fprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```

---

## Question 16 - Create and enable serverftimer.timer so it appends SERVER-F to /var/log/ (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/serverftimer.sh <<'EOF'
#!/bin/bash
echo SERVER-F >> /var/log/serverftimer.log
EOF
chmod +x /usr/local/sbin/serverftimer.sh
cat > /etc/systemd/system/serverftimer.service <<'EOF'
[Unit]
Description=Server F timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serverftimer.sh
EOF
cat > /etc/systemd/system/serverftimer.timer <<'EOF'
[Unit]
Description=Run server F timer job

[Timer]
OnCalendar=*:0/10
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serverftimer.timer
```

---

## Question 17 - Publish /var/www/html/server-f.html containing RHCSA10-F and serve httpd (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-F > /var/www/html/server-f.html
restorecon -v /var/www/html/server-f.html || true
cat > /etc/httpd/conf.d/exam-f-port.conf <<'EOF'
Listen 8205
EOF
semanage port -a -t http_port_t -p tcp 8205 2>/dev/null || semanage port -m -t http_port_t -p tcp 8205
firewall-cmd --permanent --add-port=8205/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 18 - Create enabled BaseOS and AppStream repository definitions with BaseOS a (client + server) - 4 pts

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

## Question 19 - Set maximum password age for userf10 to 50 days and warning period to 7 (client) - 4 pts

```bash
chage -M 50 -W 7 userf10
```

---

## Question 20 - Route local6 log messages to /var/log/server-f-local6.log and write a te (server) - 4 pts

```bash
# On server:
cat > /etc/rsyslog.d/server-f-local6.conf <<'EOF'
local6.* /var/log/server-f-local6.log
EOF
systemctl enable --now rsyslog
systemctl restart rsyslog
logger -p local6.info 'server-f-local6'
sleep 1
```

---

## Question 21 - Create /srv/serverf10 owned by root:serverf10 with mode 2770 (server) - 4 pts

```bash
# On server:
getent group serverf10 >/dev/null || groupadd serverf10
mkdir -p /srv/serverf10
chown root:serverf10 /srv/serverf10
chmod 2770 /srv/serverf10
```

---

## Question 22 - Create group serverf10 and user srvf10 with password cinder9, then add t (server) - 4 pts

```bash
# On server:
getent group serverf10 >/dev/null || groupadd serverf10
id srvf10 >/dev/null 2>&1 || useradd srvf10
gpasswd -a srvf10 serverf10
echo 'srvf10:cinder9' | chpasswd
```
