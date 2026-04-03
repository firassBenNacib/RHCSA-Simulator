# Mock Exam F

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-f` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22 task RHCSA style mock exam centered on chrony, SSH hardening, account defaults, rsync, and storage administration.

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
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.38/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.exam-f.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
grep -q 'db.exam-f.lab' /etc/hosts || echo '192.168.122.3 db.exam-f.lab' >> /etc/hosts
```

---

## Question 03 - Chrony Server (servervm) - 5 pts

```bash
# Run on servervm
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.122.0/24
local stratum 10
EOF
systemctl enable --now chronyd
```

---

## Question 04 - Chrony Client (clientvm) - 5 pts

```bash
cat > /etc/chrony.conf <<'EOF'
server servervm iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF
systemctl enable --now chronyd
```

---

## Question 05 - SSH Port (servervm) - 5 pts

```bash
# Run on servervm
python3 - <<'EOF'
from pathlib import Path
import re
p = Path('/etc/ssh/sshd_config')
text = p.read_text()
for key, val in [('Port', '2222'), ('PasswordAuthentication', 'yes'), ('PubkeyAuthentication', 'yes')]:
    if re.search(rf'^\s*{key}\s+', text, flags=re.M):
        text = re.sub(rf'^\s*{key}\s+.*$', f'{key} {val}', text, flags=re.M)
    else:
        text += f'\n{key} {val}\n'
p.write_text(text)
EOF
systemctl restart sshd
```

---

## Question 06 - Rich Rule (servervm) - 5 pts

```bash
# Run on servervm
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 07 - Useradd Defaults (clientvm) - 5 pts

```bash
useradd -D -f 14
```

---

## Question 08 - No-Home UID User (clientvm) - 5 pts

```bash
useradd -M -u 4560 -s /sbin/nologin pine560
echo cinder9 | passwd --stdin pine560
```

---

## Question 09 - Admin User (clientvm) - 5 pts

```bash
useradd elio
echo cinder9 | passwd --stdin elio
```

---

## Question 10 - Delegated Sudo (clientvm) - 5 pts

```bash
visudo -f /etc/sudoers.d/elio-firewalld
elio ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld
```

---

## Question 11 - SSH Key Generation (clientvm) - 5 pts

```bash
runuser -l elio -c 'ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519'
```

---

## Question 12 - Remote Account (servervm) - 5 pts

```bash
# Run on servervm
useradd backupf
echo cinder9 | passwd --stdin backupf
install -d -m 0755 -o backupf -g backupf /home/backupf/inbox
```

---

## Question 13 - Passwordless SSH (servervm) - 4 pts

```bash
runuser -l elio -c 'ssh-copy-id -p 2222 backupf@servervm'
runuser -l elio -c 'ssh -p 2222 -o BatchMode=yes backupf@servervm true'
```

---

## Question 14 - Rsync Transfer (servervm) - 4 pts

```bash
runuser -l elio -c 'rsync -e "ssh -p 2222" /opt/exam-f/aurora-report.txt backupf@servervm:/home/backupf/inbox/report.txt'
```

---

## Question 15 - User Umask (clientvm) - 4 pts

```bash
echo 'umask 027' >> /home/elio/.bash_profile
```

---

## Question 16 - Find And Copy (clientvm) - 4 pts

```bash
mkdir -p /root/seekerf-files
find /opt/exam-f/find -user seekerf -mtime -1 -type f -exec cp --parents {} /root/seekerf-files \;
```

---

## Question 17 - Grep Filter (clientvm) - 4 pts

```bash
grep comet /usr/share/dict/words > /root/comet-lines
```

---

## Question 18 - Archive (clientvm) - 4 pts

```bash
tar -czf /root/usr-local-f.tar.gz /usr/local
```

---

## Question 19 - Shell Script (clientvm) - 4 pts

```bash
vim /usr/local/bin/aurora-report
#!/bin/bash
> /root/aurora-units.txt
for unit in $(cat /usr/local/share/exam-f/units.lst); do
    systemctl is-active "$unit" >> /root/aurora-units.txt
done
chmod +x /usr/local/bin/aurora-report
/usr/local/bin/aurora-report
```

---

## Question 20 - Swap Space (clientvm) - 4 pts

```bash
fdisk /dev/sdb
# create a 704 MiB partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid> swap swap defaults 0 0
```

---

## Question 21 - Create And Mount LV (clientvm) - 4 pts

```bash
fdisk /dev/sdc
# create one Linux LVM partition that uses the disk
partprobe /dev/sdc
pvcreate /dev/sdc1
vgcreate -s 8M auroravg /dev/sdc1
lvcreate -n auroralv -l 50 auroravg
mkfs.xfs -f /dev/auroravg/auroralv
mkdir -p /mnt/auroralv
blkid /dev/auroravg/auroralv
vim /etc/fstab
UUID=<uuid> /mnt/auroralv xfs defaults 0 0
mount -a
```

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

```bash
tuned-adm profile "$(tuned-adm recommend)"
```

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.aurora.lab' && grep -Fqx '192.168.122.3 db.aurora.lab' /etc/hosts
grep -Eq '^server servervm iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^allow 192\.168\.122\.0/24$' /etc/chrony.conf && ssh admin@servervm sudo systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^Port 2222$' /etc/ssh/sshd_config && ssh admin@servervm sudo firewall-cmd --list-rich-rules | grep -Fq 'port port="2222" protocol="tcp" accept'
useradd -D | grep -Eq 'INACTIVE=14' && getent passwd pine560 | awk -F: '{print $3":"$6":"$7}' | grep -qx '4560::/sbin/nologin' && grep -Eq '^elio .*NOPASSWD: /usr/bin/systemctl restart firewalld$' /etc/sudoers.d/elio-firewalld && grep -Fqx 'umask 027' /home/elio/.bash_profile
runuser -l elio -c 'ssh -p 2222 -o BatchMode=yes backupf@servervm true' && ssh admin@servervm test -f /home/backupf/inbox/report.txt
test -f /root/seekerf-files/opt/exam-f/find/a/file1.txt && grep -q 'comet' /root/comet-lines && test -f /root/usr-local-f.tar.gz && /usr/local/bin/aurora-report >/dev/null && test -s /root/aurora-units.txt
swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt -no TARGET,SOURCE,FSTYPE /mnt/auroralv | grep -Eq '^/mnt/auroralv /dev/mapper/auroravg-auroralv xfs$' && rec="$(tuned-adm recommend | awk '{print $1}')"; act="$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\1/')"; test -n "$rec" && test "$act" = "$rec"
```
