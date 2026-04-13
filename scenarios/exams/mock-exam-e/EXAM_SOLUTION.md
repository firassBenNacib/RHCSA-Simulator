# Mock Exam E

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, software-management, filesystems-and-autofs, users-sudo-ssh, storage-lvm |

A 22 task RHCSA style mock exam focused on offline repositories, Apache document roots, ACLs, NFS, and storage maintenance.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.37/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.exam-e.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 registry.exam-e.lab
```

---

## Question 03 - Client Repositories (clientvm) - 5 pts

```bash
cat > /etc/yum.repos.d/exam-e.repo <<'EOF'
[harbor-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[harbor-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 04 - Server Repositories (servervm) - 5 pts

```bash
# Run on servervm
cat > /etc/yum.repos.d/exam-e.repo <<'EOF'
[harbor-baseos]
name=RHCSA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0
[harbor-appstream]
name=RHCSA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
EOF
dnf clean all
```

---

## Question 05 - Apache Custom Docroot (clientvm) - 5 pts

```bash
dnf install -y httpd
mkdir -p /srv/harbor-web
echo 'exam-e portal' > /srv/harbor-web/index.html
vim /etc/httpd/conf/httpd.conf
Listen 8181
cat > /etc/httpd/conf.d/harborgrid.conf <<'EOF'
<VirtualHost *:8181>
    DocumentRoot "/srv/harbor-web"
</VirtualHost>
EOF
semanage fcontext -a -t httpd_sys_content_t '/srv/harbor-web(/.*)?'
restorecon -Rv /srv/harbor-web
firewall-cmd --permanent --add-port=8181/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

---

## Question 06 - Harbor Users (clientvm) - 5 pts

```bash
groupadd harborops
useradd -G harborops lena
useradd -G harborops ivor
echo cinder9 | passwd --stdin lena
echo cinder9 | passwd --stdin ivor
```

---

## Question 07 - Password Aging (clientvm) - 5 pts

```bash
chage -M 30 -m 2 -W 7 ivor
```

---

## Question 08 - Default ACL Directory (clientvm) - 5 pts

```bash
chmod 770 /srv/harbor-drop
chmod g+s /srv/harbor-drop
```

---

## Question 09 - No-Home Remote User (clientvm) - 5 pts

```bash
useradd -M -s /sbin/nologin harborremote
echo cinder9 | passwd --stdin harborremote
```

---

## Question 10 - Pwquality Policy (clientvm) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
cat > /etc/security/pwquality.conf.d/harborgrid.conf <<'EOF'
minlen = 12
minclass = 3
EOF
```

---

## Question 11 - At Job (clientvm) - 5 pts

```bash
su - ivor
echo "echo exam-e tick >> /root/exam-e-at.log" | at now + 2 minutes
systemctl enable --now atd
```

---

## Question 12 - Direct NFS Mount (clientvm) - 5 pts

```bash
mkdir -p /mnt/harborhome
vim /etc/fstab
servervm:/exports/harborhome /mnt/harborhome nfs defaults,_netdev 0 0
mount -a
```

---

## Question 13 - Persistent Journal (servervm) - 4 pts

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

## Question 14 - Per-User Login Message (clientvm) - 4 pts

```bash
echo 'echo exam-e access' >> /home/ivor/.bash_profile
```

---

## Question 15 - Fixed UID User (clientvm) - 4 pts

```bash
useradd -M -u 4551 -s /sbin/nologin maple551
echo cinder9 | passwd --stdin maple551
```

---

## Question 16 - Find And Copy (clientvm) - 4 pts

```bash
mkdir -p /root/scoutte-files
find /opt/exam-e/find -user scoutte -mtime -1 -type f -exec cp --parents {} /root/scoutte-files \;
```

---

## Question 17 - Grep Filter (clientvm) - 4 pts

```bash
grep beacon /usr/share/dict/words > /root/beacon-lines
```

---

## Question 18 - Archive (clientvm) - 4 pts

```bash
tar -cjf /root/var-tmp-harbor.tar.bz2 /var/tmp
```

---

## Question 19 - Shell Script (clientvm) - 4 pts

```bash
vim /usr/local/bin/harbor-check
#!/bin/bash
> /root/harbor-services.txt
for svc in $(cat /usr/local/share/exam-e/services.lst); do
    systemctl is-active "$svc" >> /root/harbor-services.txt
done
chmod +x /usr/local/bin/harbor-check
/usr/local/bin/harbor-check
```

---

## Question 20 - Swap Space (clientvm) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 641MiB
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 21 - Resize Existing LV (clientvm) - 4 pts

```bash
lvextend -L 360M /dev/reviewvge/reviewe
resize2fs /dev/reviewvge/reviewe
```

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

```bash
tuned-adm recommend
tuned-adm profile <recommended-profile>
```
