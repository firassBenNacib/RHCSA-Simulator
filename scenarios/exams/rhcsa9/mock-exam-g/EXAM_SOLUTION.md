# Mock Exam G

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-g` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, filesystems-and-autofs, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam combining recovery, NFS, sticky directories, SSH key transfer, process handling, and rootless containers.

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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.39/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.deltaforge.lab
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
192.168.122.3 vault.deltaforge.lab
```

---

## Question 05 - Direct NFS Mount (client) - 5 pts

```bash
mkdir -p /mnt/delta-home
vim /etc/fstab
server:/exports/delta-home /mnt/delta-home nfs defaults,_netdev 0 0
mount -a
```

---

## Question 06 - Ops User And Group (client) - 5 pts

```bash
getent group deltaops >/dev/null || groupadd deltaops
id pavel >/dev/null 2>&1 || useradd -m -G deltaops pavel
echo cinder9 | passwd --stdin pavel
```

---

## Question 07 - Sticky Shared Directory (client) - 5 pts

```bash
mkdir -p /projects/delta-drop
chown root:deltaops /projects/delta-drop
chmod 3770 /projects/delta-drop
```

---

## Question 08 - No-Home Audit User (client) - 5 pts

```bash
id auditg >/dev/null 2>&1 || useradd -M -s /sbin/nologin auditg
usermod -s /sbin/nologin auditg
rm -rf /home/auditg
```

---

## Question 09 - Password Aging And Umask (client) - 5 pts

```bash
chage -M 45 -m 5 -W 7 pavel
echo 'umask 027' >> /home/pavel/.bash_profile
```

---

## Question 10 - Copy User On Both Systems (client) - 5 pts

```bash
id copyg >/dev/null 2>&1 || useradd -m copyg
echo cinder9 | passwd --stdin copyg
# Run on server
id copyg >/dev/null 2>&1 || useradd -m copyg
echo cinder9 | passwd --stdin copyg
mkdir -p /home/copyg/inbox
chown copyg:copyg /home/copyg/inbox
chmod 0755 /home/copyg/inbox
```

---

## Question 11 - SSH Key And Secure Copy (client + server) - 5 pts

```bash
install -d -m 700 -o copyg -g copyg /home/copyg/.ssh
test -f /home/copyg/.ssh/id_ed25519 || runuser -u copyg -- ssh-keygen -t ed25519 -N '' -f /home/copyg/.ssh/id_ed25519 -C copyg-exam-replay >/dev/null 2>&1
chmod 0600 /home/copyg/.ssh/id_ed25519
chmod 0644 /home/copyg/.ssh/id_ed25519.pub
# Run on client
su - copyg
ssh-copy-id -i /home/copyg/.ssh/id_ed25519.pub copyg@server
scp -o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /opt/exam-g/copyg-payload.txt copyg@server:/home/copyg/inbox/payload.txt
```

---

## Question 12 - At Job (client) - 5 pts

```bash
systemctl enable --now atd
runuser -l pavel -c 'echo "echo exam-g tick >> /root/exam-g-at.log" | at now + 2 minutes'
```

---

## Question 13 - Per-User Login Message (client) - 4 pts

```bash
echo 'echo exam-g access' >> /home/pavel/.bash_profile
```

---

## Question 14 - Find And Copy (client) - 4 pts

```bash
mkdir -p /root/trackerg-files
find /opt/exam-g/find -user trackerg -mtime -1 -type f -exec cp --parents {} /root/trackerg-files \;
```

---

## Question 15 - Grep Filter (client) - 4 pts

```bash
grep ember /usr/share/dict/words > /root/ember-lines
```

---

## Question 16 - Archive (client) - 4 pts

```bash
tar -cjf /root/etc-g.tar.bz2 /etc
```

---

## Question 17 - Persistent Journal (client) - 4 pts

```bash
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
```

---

## Question 18 - Process Renice And Kill (client) - 4 pts

```bash
cpu_pid=$(cat /home/workerg/cpu.pid 2>/dev/null || true)
if [ -n "$cpu_pid" ]; then kill "$cpu_pid" 2>/dev/null || true; fi
sleep_pid=$(cat /home/workerg/sleep.pid 2>/dev/null || true)
if [ -z "$sleep_pid" ] || ! ps -p "$sleep_pid" >/dev/null 2>&1; then runuser -l workerg -c 'nohup sleep 7200 >/dev/null 2>&1 & echo $! > ~/sleep.pid'; sleep_pid=$(cat /home/workerg/sleep.pid); fi
renice 10 -p "$sleep_pid"
```

---

## Question 19 - Swap Space (client) - 4 pts

```bash
swapoff /dev/sdb1 >/dev/null 2>&1 || true
sed -i -E '\#^[^[:space:]]+[[:space:]]+swap[[:space:]]+swap[[:space:]]#d' /etc/fstab
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 737MiB
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

## Question 20 - Create And Mount LV (client) - 4 pts

```bash
umount /mnt/reviewa /mnt/reviewb /mnt/reviewc /mnt/summitlv /mnt/auroralv /mnt/deltalv /mnt/reviewh >/dev/null 2>&1 || true
swapoff /dev/sdc1 >/dev/null 2>&1 || true
for vg in reviewvga reviewvgb reviewvgc summitvg auroravg deltavg reviewvgh; do vgchange -an "$vg" >/dev/null 2>&1 || true; vgremove -ff "$vg" >/dev/null 2>&1 || true; done
pvremove -ff -y /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sed -i -E '\# /mnt/(reviewa|reviewb|reviewc|summitlv|auroralv|deltalv|reviewh) #d' /etc/fstab
parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 701MiB set 1 lvm on
blockdev --rereadpt /dev/sdc || true
partprobe /dev/sdc || true
partx -u /dev/sdc || partx -a /dev/sdc || true
udevadm settle
for attempt in 1 2 3 4 5 6 7 8 9 10; do test -b /dev/sdc1 && break; blockdev --rereadpt /dev/sdc || true; partprobe /dev/sdc || true; partx -u /dev/sdc || partx -a /dev/sdc || true; udevadm settle; sleep 1; done
test -b /dev/sdc1
pvcreate /dev/sdc1
vgcreate -s 16M deltavg /dev/sdc1
lvcreate -y -W y -n deltalv -l 40 deltavg
mkfs.ext4 /dev/deltavg/deltalv
mkdir -p /mnt/deltalv
uuid=$(blkid -s UUID -o value /dev/deltavg/deltalv)
echo "UUID=$uuid /mnt/deltalv ext4 defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 21 - Rootless Container (client) - 4 pts

```bash
mkdir -p /opt/inc /opt/outg /opt/rhcsa/workspaces/exam-g/site-content
echo 'exam g container' > /opt/rhcsa/workspaces/exam-g/site-content/index.html
cat > /opt/rhcsa/workspaces/exam-g/Containerfile <<'EOF'
FROM localhost/rhcsa-httpd-base:latest
COPY site-content/ /var/www/html/
CMD ["/usr/bin/bash", "-lc", "while true; do sleep 300; done"]
EOF
chown -R solg:solg /opt/rhcsa/workspaces/exam-g /opt/inc /opt/outg
su - solg
cd /opt/rhcsa/workspaces/exam-g
podman rmi -f localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || true
podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar
podman build -t localhost/deltaforge-web:latest .
podman run -d --name pdfg -v /opt/inc:/data/input:Z -v /opt/outg:/data/output:Z localhost/deltaforge-web:latest
exit
```

---

## Question 22 - Container Autostart (client) - 4 pts

```bash
loginctl enable-linger solg
uid=$(id -u solg)
systemctl start "user@$uid.service" || true
for i in $(seq 1 20); do test -S "/run/user/$uid/bus" && break; sleep 1; done
test -S "/run/user/$uid/bus"
runuser -l solg -c 'mkdir -p ~/.config/systemd/user'
runuser -l solg -c 'cd ~/.config/systemd/user && podman generate systemd --name pdfg --files'
runuser -l solg -c 'podman kill pdfg >/dev/null 2>&1 || true'
runuser -l solg -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus systemctl --user daemon-reload'
runuser -l solg -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus systemctl --user enable --now container-pdfg.service'
```
