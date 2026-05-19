# Mock Exam C

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, filesystems-and-autofs, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam centered on recovery, boot persistence, NFS, ACLs, journald, and rootless containers.

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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.28/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.exam-c.lab
```

---

## Question 03 - Bootloader Kernel Argument (client) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

---

## Question 04 - Host Entry (client) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 vault.exam-c.lab
```

---

## Question 05 - Direct NFS Mount (client) - 5 pts

```bash
mkdir -p /mnt/bluec
vim /etc/fstab
server:/exports/bluec /mnt/bluec nfs defaults,_netdev 0 0
mount -a
```

---

## Question 06 - Users And Group (client) - 5 pts

```bash
getent group infrac >/dev/null || groupadd infrac
id talia >/dev/null 2>&1 || useradd -m talia
id ren >/dev/null 2>&1 || useradd -m ren
usermod -aG infrac talia
usermod -aG infrac ren
echo cinder9 | passwd --stdin talia
echo cinder9 | passwd --stdin ren
```

---

## Question 07 - Default ACL Directory (client) - 5 pts

```bash
mkdir -p /srv/infrac
chown root:infrac /srv/infrac
chmod 2770 /srv/infrac
setfacl -d -m g:infrac:rwx /srv/infrac
```

---

## Question 08 - No-Home User (client) - 5 pts

```bash
id remote63 >/dev/null 2>&1 || useradd -M -s /sbin/nologin remote63
usermod -s /sbin/nologin remote63
rm -rf /home/remote63
```

---

## Question 09 - At Job (client) - 5 pts

```bash
echo 'echo "exam-c audit" >> /root/exam-c-at.log' | at now + 2 minutes
systemctl enable --now atd
```

---

## Question 10 - Per-User Password Aging (client) - 5 pts

```bash
chage -M 45 -m 5 -W 7 talia
```

---

## Question 11 - Persistent Journal (server) - 5 pts

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

---

## Question 12 - User Umask (client) - 5 pts

```bash
echo 'umask 027' >> /home/ren/.bash_profile
```

---

## Question 13 - Per-User Login Message (client) - 4 pts

```bash
echo 'echo exam-c access' >> /home/ren/.bash_profile
```

---

## Question 14 - Fixed UID User (client) - 4 pts

```bash
id kian431 >/dev/null 2>&1 || useradd -u 4431 kian431
usermod -u 4431 kian431
echo cinder9 | passwd --stdin kian431
```

---

## Question 15 - Find And Copy (client) - 4 pts

```bash
mkdir -p /root/ren-files
find /opt/exam-c/find -type f -user ren -mtime -1 -exec cp --parents {} /root/ren-files \;
```

---

## Question 16 - Grep Filter (client) - 4 pts

```bash
grep orbit /usr/share/dict/words > /root/orbit-lines
```

---

## Question 17 - Archive (client) - 4 pts

```bash
tar -cjf /root/etc-c.tar.bz2 /etc
```

---

## Question 18 - Service Status Script (client) - 4 pts

```bash
cat > /usr/local/bin/northcheck <<'SCRIPT'
#!/usr/bin/env bash
while read -r svc; do
  systemctl is-active "$svc" >> /root/north-services.txt || true
done < /usr/local/share/exam-c/check.lst
SCRIPT
chmod 755 /usr/local/bin/northcheck
/usr/local/bin/northcheck
```

---

## Question 19 - Swap Space (client) - 4 pts

```bash
swapoff /dev/sdb1 >/dev/null 2>&1 || true
sed -i -E '\#^[^[:space:]]+[[:space:]]+swap[[:space:]]+swap[[:space:]]#d' /etc/fstab
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 701MiB
blockdev --rereadpt /dev/sdb || true
partprobe /dev/sdb || true
partx -u /dev/sdb || partx -a /dev/sdb || true
udevadm settle
for attempt in 1 2 3 4 5 6 7 8 9 10; do test -b /dev/sdb1 && break; blockdev --rereadpt /dev/sdb || true; partprobe /dev/sdb || true; partx -u /dev/sdb || partx -a /dev/sdb || true; udevadm settle; sleep 1; done
test -b /dev/sdb1
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 20 - Resize Existing LV (client) - 4 pts

```bash
lvextend -L 340M /dev/reviewvgc/reviewc
resize2fs /dev/reviewvgc/reviewc
```

---

## Question 21 - Rootless Container (client) - 4 pts

```bash
mkdir -p /opt/inc /opt/outc /opt/rhcsa/workspaces/exam-c/site-content
echo 'exam c container' > /opt/rhcsa/workspaces/exam-c/site-content/index.html
cat > /opt/rhcsa/workspaces/exam-c/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
CMD ["/usr/bin/bash", "-lc", "while true; do sleep 300; done"]
EOF
chown -R eirac:eirac /opt/rhcsa/workspaces/exam-c /opt/inc /opt/outc
su - eirac
cd /opt/rhcsa/workspaces/exam-c
podman rmi -f localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || true
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar
podman build -t localhost/northstar-web:latest .
podman run -d --name pdfc -v /opt/inc:/data/input:Z -v /opt/outc:/data/output:Z localhost/northstar-web:latest
exit
```

---

## Question 22 - Container Autostart (client) - 4 pts

```bash
loginctl enable-linger eirac
uid=$(id -u eirac)
systemctl start "user@$uid.service" || true
for i in $(seq 1 20); do test -S "/run/user/$uid/bus" && break; sleep 1; done
test -S "/run/user/$uid/bus"
runuser -l eirac -c 'mkdir -p ~/.config/systemd/user'
runuser -l eirac -c 'cd ~/.config/systemd/user && podman generate systemd --name pdfc --files'
runuser -l eirac -c 'podman kill pdfc >/dev/null 2>&1 || true'
runuser -l eirac -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus systemctl --user daemon-reload'
runuser -l eirac -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus systemctl --user enable --now container-pdfc.service'
```
