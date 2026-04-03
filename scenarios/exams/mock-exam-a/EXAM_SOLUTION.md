# Mock Exam A: OpsEdge Integrated Review

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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

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
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.26/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.opsedge.lab
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
sed -i 's/^Listen .*/Listen 8282/' /etc/httpd/conf/httpd.conf
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8282/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8282 || semanage port -m -t http_port_t -p tcp 8282
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
install -d -m 2770 -o root -g sysopsa /srv/sysopsa
```

---

## Question 11 - Cron Logger (clientvm) - 5 pts

```bash
crontab -e -u amber
*/2 * * * * logger "OpsEdge tick"
```

---

## Question 12 - Host Entry (clientvm) - 5 pts

```bash
grep -q 'api.opsedge.lab' /etc/hosts || echo '192.168.122.3 api.opsedge.lab' >> /etc/hosts
```

---

## Question 13 - Find And Copy (clientvm) - 4 pts

```bash
find /opt/exam-a/find -type f -user amber -mtime -1 -exec cp --parents {} /root/amber-files \;
```

---

## Question 14 - Grep Filter (clientvm) - 4 pts

```bash
grep delta /usr/share/dict/words > /root/delta-lines
```

---

## Question 15 - Archive (clientvm) - 4 pts

```bash
tar -cjf /root/etc-opsa.tar.bz2 /etc
```

---

## Question 16 - Service Audit Script (clientvm) - 4 pts

```bash
vim /usr/local/bin/opsa-report
#!/usr/bin/env bash
while read -r svc; do
  systemctl is-active "$svc" >> /root/opsa-services.txt
done < /usr/local/share/exam-a/services.lst
chmod 755 /usr/local/bin/opsa-report
/usr/local/bin/opsa-report
```

---

## Question 17 - Swap Space (clientvm) - 4 pts

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

## Question 18 - Resize Existing LV (clientvm) - 4 pts

```bash
lvextend -L 320M /dev/reviewvga/reviewa
resize2fs /dev/reviewvga/reviewa
```

---

## Question 19 - Rootless Container (clientvm) - 4 pts

```bash
su - oriona
cd /opt/rhcsa/workspaces/exam-a
podman build -t localhost/opsa-web:latest .
podman run -d --name pdfa -v /opt/ina:/data/input:Z -v /opt/outa:/data/output:Z localhost/opsa-web:latest
exit
```

---

## Question 20 - Container Autostart (clientvm) - 4 pts

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

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.opsedge.lab' && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192' && grep -Fqx '192.168.122.3 api.opsedge.lab' /etc/hosts
curl -fsS http://localhost:8282 >/dev/null && semanage port -l | grep -Eq '^http_port_t\b.*\b8282\b' && curl -fsS http://servervm/repo/BaseOS/repodata/repomd.xml >/dev/null && ssh admin@servervm sudo curl -fsS http://servervm/repo/AppStream/repodata/repomd.xml >/dev/null
getent group sysopsa >/dev/null && id -nG violet | tr ' ' '\n' | grep -qx sysopsa && id -nG amber | tr ' ' '\n' | grep -qx sysopsa && getent passwd frost | awk -F: '{print $6":"$7}' | grep -qx ':/sbin/nologin' && grep -Eq '^%sysopsa .* /usr/sbin/useradd$' /etc/sudoers.d/sysopsa-useradd && grep -Eq '^violet .*NOPASSWD: /usr/bin/passwd$' /etc/sudoers.d/violet-passwd && stat -c '%U:%G %a' /srv/sysopsa | grep -qx 'root:sysopsa 2770' && crontab -l -u amber | grep -Fqx '*/2 * * * * logger "OpsEdge tick"'
getent passwd ash420 | awk -F: '{print $3}' | grep -qx '4420' && test -f /root/amber-files/opt/exam-a/find/a/file1.txt && grep -qx 'delta' /root/delta-lines && test -f /root/etc-opsa.tar.bz2 && /usr/local/bin/opsa-report >/dev/null && test -s /root/opsa-services.txt
swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewa" && $2=="reviewvga" && $3>=319 && $3<=321{f=1} END{exit !f}'
runuser -l oriona -c 'podman ps --format {{.Names}}' | grep -qx pdfa && runuser -l oriona -c 'systemctl --user is-enabled container-pdfa.service' | grep -qx enabled && loginctl show-user oriona | grep -Eq '^Linger=yes$' && ssh admin@servervm sudo test -d /var/log/journal
```
