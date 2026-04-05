# Mock Exam A

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-a` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam focused on recovery, repositories, Apache, sudo delegation, storage, and rootless containers.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (clientvm) - 5 pts

```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

## Question 02 - Client Network (clientvm) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.26/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.exam-a.lab
```

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

---

## Question 04 - Client Repositories (clientvm) - 5 pts

```bash
cat > /etc/yum.repos.d/opsa.repo <<'EOF'
[opsa-baseos]
name=OpsA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[opsa-appstream]
name=OpsA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 05 - Server Repositories (servervm) - 5 pts

```bash
# Run on servervm
cat > /etc/yum.repos.d/opsa.repo <<'EOF'
[opsa-baseos]
name=OpsA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[opsa-appstream]
name=OpsA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 06 - Apache SELinux Port (clientvm) - 5 pts

```bash
vim /etc/httpd/conf/httpd.conf
Listen 8282
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8282/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8282
systemctl restart httpd
```

---

## Question 07 - Users And Group (clientvm) - 5 pts

```bash
groupadd sysopsa
useradd -G sysopsa violet
useradd -G sysopsa amber
useradd -M -s /sbin/nologin frost
```

---

## Question 08 - User Passwords (clientvm) - 5 pts

```bash
echo cinder9 | passwd --stdin violet
echo cinder9 | passwd --stdin amber
echo cinder9 | passwd --stdin frost
```

---

## Question 09 - Delegated Sudo (clientvm) - 5 pts

```bash
visudo -f /etc/sudoers.d/sysopsa-useradd
%sysopsa ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/violet-passwd
violet ALL=(root) NOPASSWD: /usr/bin/passwd
```

---

## Question 10 - Setgid Directory (clientvm) - 5 pts

```bash
chmod 770 /srv/sysopsa
chmod g+s /srv/sysopsa
```

---

## Question 11 - Cron Logger (clientvm) - 5 pts

```bash
crontab -e -u amber
*/2 * * * * logger "exam-a tick"
```

---

## Question 12 - Host Entry (clientvm) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 api.exam-a.lab
```

---

## Question 13 - Swap Space (clientvm) - 4 pts

```bash
fdisk /dev/sdb
# create a 512M GPT partition and set the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid-of-sdb1> swap swap defaults 0 0
```

---

## Question 14 - Resize Existing LV (clientvm) - 4 pts

```bash
lvextend -L 320M /dev/reviewvga/reviewa
resize2fs /dev/reviewvga/reviewa
```

---

## Question 15 - Rootless Container (clientvm) - 4 pts

```bash
su - oriona
cd /opt/rhcsa/workspaces/exam-a
podman build -t localhost/opsa-web:latest .
podman run -d --name pdfa -v /opt/ina:/data/input:Z -v /opt/outa:/data/output:Z localhost/opsa-web:latest
exit
```

---

## Question 16 - Container Autostart (clientvm) - 4 pts

```bash
su - oriona
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name pdfa --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-pdfa.service
exit
loginctl enable-linger oriona
```

---

## Question 17 - Persistent Journal (servervm) - 4 pts

```bash
# Run on servervm
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```

---

## Question 18 - Persistent Journal (servervm) - 4 pts

```bash
# Run on servervm
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```

---

## Question 19 - Persistent Journal (servervm) - 4 pts

```bash
# Run on servervm
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```

---

## Question 20 - Persistent Journal (servervm) - 4 pts

```bash
# Run on servervm
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```

---

## Question 21 - Persistent Journal (servervm) - 4 pts

```bash
# Run on servervm
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```

---

## Question 22 - Persistent Journal (servervm) - 4 pts

```bash
# Run on servervm
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```
