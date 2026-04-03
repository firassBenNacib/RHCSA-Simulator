# Mock Exam E: HarborGrid Services Review

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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm) - 5 pts

```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.37/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.harborgrid.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
grep -q 'registry.harbor.lab' /etc/hosts || echo '192.168.122.3 registry.harbor.lab' >> /etc/hosts
```

---

## Question 03 - Client Repositories (clientvm) - 5 pts

```bash
cat > /etc/yum.repos.d/harborgrid.repo <<'EOF'
[harbor-baseos]
name=HarborGrid BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[harbor-appstream]
name=HarborGrid AppStream
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
cat > /etc/yum.repos.d/harborgrid.repo <<'EOF'
[harbor-baseos]
name=HarborGrid BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[harbor-appstream]
name=HarborGrid AppStream
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
printf 'HarborGrid portal\n' > /srv/harbor-web/index.html
sed -i 's/^Listen .*/Listen 8181/' /etc/httpd/conf/httpd.conf
cat > /etc/httpd/conf.d/harborgrid.conf <<'EOF'
<VirtualHost *:8181>
    DocumentRoot "/srv/harbor-web"
</VirtualHost>
EOF
semanage fcontext -a -t httpd_sys_content_t '/srv/harbor-web(/.*)?' || semanage fcontext -m -t httpd_sys_content_t '/srv/harbor-web(/.*)?'
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
install -d -m 2770 -o root -g harborops /srv/harbor-drop
setfacl -d -m g:harborops:rwx /srv/harbor-drop
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
runuser -l ivor -c 'echo "echo HarborGrid tick >> /root/harbor-at.log" | at now + 2 minutes'
systemctl enable --now atd
```

---

## Question 12 - Direct NFS Mount (clientvm) - 5 pts

```bash
mkdir -p /mnt/harborhome
grep -q '/mnt/harborhome' /etc/fstab || echo 'servervm:/exports/harborhome /mnt/harborhome nfs defaults,_netdev 0 0' >> /etc/fstab
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
echo 'echo HarborGrid access' >> /home/ivor/.bash_profile
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
fdisk /dev/sdb
# create a 640 MiB partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid> swap swap defaults 0 0
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
tuned-adm recommended
tuned-adm profile <recommended-profile>
```

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.harborgrid.lab' && grep -Fqx '192.168.122.3 registry.harbor.lab' /etc/hosts && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
curl -fsS http://localhost:8181 | grep -Fq 'HarborGrid portal' && findmnt -no TARGET,SOURCE /mnt/harborhome | grep -Eq '^/mnt/harborhome servervm:/exports/harborhome$'
getent group harborops >/dev/null && id -nG lena | tr ' ' '\n' | grep -qx harborops && id -nG ivor | tr ' ' '\n' | grep -qx harborops && chage -l ivor | grep -Eq 'Maximum.*30' && getfacl -p /srv/harbor-drop | grep -Fq 'default:group:harborops:rwx' && getent passwd harborremote | awk -F: '{print $6":"$7}' | grep -qx ':/sbin/nologin' && grep -Eq '^minlen\s*=\s*12$' /etc/security/pwquality.conf.d/harborgrid.conf && grep -Eq '^minclass\s*=\s*3$' /etc/security/pwquality.conf.d/harborgrid.conf && atq | grep -q ivor && grep -Fqx 'echo HarborGrid access' /home/ivor/.bash_profile && ssh admin@servervm sudo test -d /var/log/journal
getent passwd maple551 | awk -F: '{print $3":"$6":"$7}' | grep -qx '4551::/sbin/nologin' && test -f /root/scoutte-files/opt/exam-e/find/a/file1.txt && grep -q 'beacon' /root/beacon-lines && test -f /root/var-tmp-harbor.tar.bz2 && /usr/local/bin/harbor-check >/dev/null && test -s /root/harbor-services.txt
swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewe" && $2=="reviewvge" && $3>=359 && $3<=361{f=1} END{exit !f}'
rec="$(tuned-adm recommend | awk '{print $1}')"; act="$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\1/')"; test -n "$rec" && test "$act" = "$rec"
```
