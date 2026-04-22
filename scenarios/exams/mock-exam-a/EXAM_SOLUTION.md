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
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (client) - 5 pts

```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

## Question 02 - Client Network (client) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.26/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.exam-a.lab
```

---

## Question 03 - Bootloader Kernel Argument (client) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

---

## Question 04 - Client Repositories (client) - 5 pts

```bash
cat > /etc/yum.repos.d/opsa.repo <<'EOF'
[opsa-baseos]
name=OpsA BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[opsa-appstream]
name=OpsA AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 05 - Server Repositories (server) - 5 pts

```bash
# Run on server
cat > /etc/yum.repos.d/opsa.repo <<'EOF'
[opsa-baseos]
name=OpsA BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[opsa-appstream]
name=OpsA AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 06 - Apache SELinux Port (client) - 5 pts

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

## Question 07 - Users And Group (client) - 5 pts

```bash
groupadd sysopsa
useradd -G sysopsa violet
useradd -G sysopsa amber
useradd -M -s /sbin/nologin frost
```

---

## Question 08 - User Passwords (client) - 5 pts

```bash
echo cinder9 | passwd --stdin violet
echo cinder9 | passwd --stdin amber
echo cinder9 | passwd --stdin frost
```

---

## Question 09 - Delegated Sudo (client) - 5 pts

```bash
visudo -f /etc/sudoers.d/sysopsa-useradd
%sysopsa ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/violet-passwd
violet ALL=(root) NOPASSWD: /usr/bin/passwd
```

---

## Question 10 - Setgid Directory (client) - 5 pts

```bash
mkdir -p /srv/sysopsa
chown root:sysopsa /srv/sysopsa
chmod 2770 /srv/sysopsa
```

---

## Question 11 - Cron Logger (client) - 5 pts

```bash
crontab -e -u amber
*/2 * * * * logger "exam-a tick"
```

---

## Question 12 - Host Entry (client) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 api.exam-a.lab
```

---

## Question 13 - Fixed UID User (client) - 4 pts

```bash
useradd -u 4420 ash420
echo cinder9 | passwd --stdin ash420
```

---

## Question 14 - Find And Copy (client) - 4 pts

```bash
mkdir -p /root/amber-files
find /opt/exam-a/find -user amber -mtime -1 -type f -exec cp --parents {} /root/amber-files \;
```

---

## Question 15 - Grep Filter (client) - 4 pts

```bash
grep delta /usr/share/dict/words > /root/delta-lines
```

---

## Question 16 - Archive (client) - 4 pts

```bash
tar -cjf /root/etc-opsa.tar.bz2 /etc
```

---

## Question 17 - Service Report Script (client) - 4 pts

```bash
cat > /usr/local/bin/opsa-report <<'SCRIPT'
#!/bin/bash
> /root/opsa-services.txt
for svc in $(cat /usr/local/share/exam-a/services.lst); do
  systemctl is-active "$svc" >> /root/opsa-services.txt
done
SCRIPT
chmod +x /usr/local/bin/opsa-report
/usr/local/bin/opsa-report
```

---

## Question 18 - Swap Space (client) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 701MiB
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 19 - Resize Existing LV (client) - 4 pts

```bash
lvextend -L 320M /dev/reviewvga/reviewa
resize2fs /dev/reviewvga/reviewa
```

---

## Question 20 - Rootless Container (client) - 4 pts

```bash
su - oriona
cd /opt/rhcsa/workspaces/exam-a
podman build -t localhost/opsa-web:latest .
podman run -d --name pdfa -v /opt/inc:/data/input:Z -v /opt/outa:/data/output:Z localhost/opsa-web:latest
exit
```

---

## Question 21 - Container Autostart (client) - 4 pts

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

## Question 22 - Persistent Journal (server) - 4 pts

```bash
# Run on server
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```
