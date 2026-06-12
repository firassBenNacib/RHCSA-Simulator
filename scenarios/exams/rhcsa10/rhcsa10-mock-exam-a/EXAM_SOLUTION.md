# RHCSA 10 Mock Exam A

## Exam Solution
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

```bash
# Boot into emergency mode: at GRUB, press 'e', append rd.break to the linux line, Ctrl+X
# mount -o remount,rw /sysroot
# chroot /sysroot
# echo cinder9 | passwd --stdin root
# touch /.autorelabel
# exit; exit
```

---

## Question 02 - Set the hostname on client to clienta.exam10.lab (client) - 5 pts

```bash
hostnamectl set-hostname clienta.exam10.lab
echo '192.168.122.3 servera.exam10.lab' >> /etc/hosts
```

---

## Question 03 - Configure the network connection for eth1 on client with the following s (client) - 5 pts

```bash
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.60/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection up "System eth1"
```

---

## Question 04 - Configure the bootloader on client so every installed kernel boots with (client) - 5 pts

```bash
grubby --update-kernel=ALL --args='audit_backlog_limit=8192'
```

---

## Question 05 - On client and server, create enabled BaseOS and AppStream repository def (client + server) - 5 pts

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

## Question 06 - set hostname to servera.exam10.lab and map clienta.exam10.lab to 192.168 (server) - 5 pts

```bash
# On server:
hostnamectl set-hostname servera.exam10.lab
grep -Eq '^192\.168\.122\.4[[:space:]]+clienta\.exam10\.lab$' /etc/hosts || echo '192.168.122.4 clienta.exam10.lab' >> /etc/hosts
```

---

## Question 07 - add a system-level Flatpak remote named examaflatpak pointing to file:// (client) - 5 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify examaflatpak file:///opt/rhcsa/flatpak/repo
flatpak install --system -y examaflatpak org.rhcsa.Tools
flatpak list --system --app
```

---

## Question 08 - Create group opsa10 on client (client) - 5 pts

```bash
groupadd opsa10
useradd -G opsa10 anna10
useradd -G opsa10 atlas10
echo cinder9 | passwd --stdin anna10
echo cinder9 | passwd --stdin atlas10
```

---

## Question 09 - allow members of %opsa10 to run /usr/bin/systemctl without a password pr (client) - 4 pts

```bash
echo '%opsa10 ALL=(ALL) NOPASSWD: /usr/bin/systemctl' > /etc/sudoers.d/opsa10
chmod 440 /etc/sudoers.d/opsa10
```

---

## Question 10 - set the maximum password age for anna10 to 45 days and the password warn (client) - 4 pts

```bash
chage -M 45 -W 7 anna10
```

---

## Question 11 - Create an executable script /usr/local/bin/a-who on client that accepts (client) - 4 pts

```bash
cat > /usr/local/bin/a-who <<'EOF'
#!/bin/bash
test -n "${1:-}" || exit 2
id -gn "$1"
EOF
chmod +x /usr/local/bin/a-who
```

---

## Question 12 - write all usernames whose login shell ends with sh to /root/a-shell-user (client) - 4 pts

```bash
awk -F: '$7 ~ /sh$/ {print $1}' /etc/passwd | sort > /root/a-shell-users.txt
```

---

## Question 13 - create /root/exam-a-report.txt containing REPORT-A and copy it to server (client) - 4 pts

```bash
echo REPORT-A > /root/exam-a-report.txt
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-exam >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/exam-a-report.txt root@server:/root/exam-a-report.txt
```

---

## Question 14 - publish /var/www/html/server-a.html containing RHCSA10-A and serve httpd (server) - 4 pts

```bash
# On server:
mkdir -p /var/www/html
echo RHCSA10-A > /var/www/html/server-a.html
restorecon -v /var/www/html/server-a.html || true
cat > /etc/httpd/conf.d/exam-a-port.conf <<'EOF'
Listen 8200
EOF
semanage port -a -t http_port_t -p tcp 8200 2>/dev/null || semanage port -m -t http_port_t -p tcp 8200
firewall-cmd --permanent --add-port=8200/tcp
firewall-cmd --reload
systemctl enable --now httpd
systemctl restart httpd
```

---

## Question 15 - create and enable serveratimer.timer so it appends SERVER-A to /var/log/ (server) - 4 pts

```bash
# On server:
cat > /usr/local/sbin/serveratimer.sh <<'EOF'
#!/bin/bash
echo SERVER-A >> /var/log/serveratimer.log
EOF
chmod +x /usr/local/sbin/serveratimer.sh
cat > /etc/systemd/system/serveratimer.service <<'EOF'
[Unit]
Description=Server A timer job

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/serveratimer.sh
EOF
cat > /etc/systemd/system/serveratimer.timer <<'EOF'
[Unit]
Description=Run server A timer job

[Timer]
OnCalendar=*:/10
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now serveratimer.timer
```

---

## Question 16 - create volume group vga10 from /dev/sdb (client) - 4 pts

```bash
pvcreate /dev/sdb
vgcreate vga10 /dev/sdb
lvcreate -L 384M -n dataa vga10
mkfs.xfs /dev/vga10/dataa
mkdir -p /mnt/dataa10
echo '/dev/vga10/dataa /mnt/dataa10 xfs defaults 0 0' >> /etc/fstab
mount -a
```

---

## Question 17 - create group servera10 and user srva10 with password cinder9, then add t (server) - 4 pts

```bash
# On server:
getent group servera10 >/dev/null || groupadd servera10
id srva10 >/dev/null 2>&1 || useradd srva10
gpasswd -a srva10 servera10
echo 'srva10:cinder9' | chpasswd
```

---

## Question 18 - create /srv/servera10 owned by root:servera10 with mode 2770 (server) - 4 pts

```bash
# On server:
getent group servera10 >/dev/null || groupadd servera10
mkdir -p /srv/servera10
chown root:servera10 /srv/servera10
chmod 2770 /srv/servera10
```

---

## Question 19 - persistently enable the SELinux boolean httpd_can_network_connect (server) - 4 pts

```bash
# On server:
setsebool -P httpd_can_network_connect on
getsebool httpd_can_network_connect
```

---

## Question 20 - create the directory /srv/opsa10 owned by root:opsa10 with mode 3770 (se (client) - 4 pts

```bash
mkdir -p /srv/opsa10
chown root:opsa10 /srv/opsa10
chmod 3770 /srv/opsa10
```

---

## Question 21 - enable persistent systemd journal storage (server) - 4 pts

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

## Question 22 - make chronyd available as the lab time source. On client, configure chro (client + server) - 4 pts

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

## Question 23 - export /exports/exam-a to the 192.168.122.0/24 network. On client, mount (client + server) - 4 pts

```bash
# On server:
mkdir -p /exports/exam-a
echo 'exam a export' > /exports/exam-a/README
cat > /etc/exports.d/exam-a-integrated.exports <<'EOF'
/exports/exam-a 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
exportfs -arv
# On client:
mkdir -p /mnt/aprojects
grep -Eq '^server:/exports/exam-a[[:space:]]+/mnt/aprojects[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/exam-a /mnt/aprojects nfs defaults,_netdev 0 0' >> /etc/fstab
mount -a
```
