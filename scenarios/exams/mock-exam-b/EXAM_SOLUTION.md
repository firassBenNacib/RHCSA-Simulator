# Mock Exam B

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22 task RHCSA style mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.

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
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.27/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.exam-b.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
grep -q 'registry.exam-b.lab' /etc/hosts || echo '192.168.122.3 registry.exam-b.lab' >> /etc/hosts
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

## Question 05 - Useradd Defaults (clientvm) - 5 pts

```bash
useradd -D -f 20
```

---

## Question 06 - No-Home UID User (clientvm) - 5 pts

```bash
useradd -M -u 4421 cato421
echo cinder9 | passwd --stdin cato421
```

---

## Question 07 - Primary Login User (clientvm) - 5 pts

```bash
useradd mira
echo cinder9 | passwd --stdin mira
```

---

## Question 08 - Password Aging (clientvm) - 5 pts

```bash
useradd jonas
echo cinder9 | passwd --stdin jonas
chage -M 45 -m 5 -W 7 jonas
```

---

## Question 09 - Pwquality Policy (clientvm) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
cat > /etc/security/pwquality.conf.d/coremesh.conf <<'EOF'
minlen = 12
minclass = 3
EOF
```

---

## Question 10 - Delegated Sudo (clientvm) - 5 pts

```bash
visudo -f /etc/sudoers.d/mira-firewalld
mira ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld
```

---

## Question 11 - SSH Port (servervm) - 5 pts

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

## Question 12 - Rich Rule (servervm) - 5 pts

```bash
# Run on servervm
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 13 - SSH Key Generation (clientvm) - 4 pts

```bash
runuser -l mira -c 'ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519'
```

---

## Question 14 - Passwordless SSH (servervm) - 4 pts

```bash
# Run on servervm
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
install -d -m 0755 -o meshremote -g meshremote /home/meshremote/inbox
runuser -l mira -c 'ssh-copy-id -p 2222 meshremote@servervm'
runuser -l mira -c 'ssh -p 2222 -o BatchMode=yes meshremote@servervm true'
```

---

## Question 15 - Rsync Transfer (servervm) - 4 pts

```bash
runuser -l mira -c 'rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@servervm:/home/meshremote/inbox/report.txt'
```

---

## Question 16 - Passwordless SSH (servervm) - 4 pts

```bash
# Run on servervm
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
install -d -m 0755 -o meshremote -g meshremote /home/meshremote/inbox
runuser -l mira -c 'ssh-copy-id -p 2222 meshremote@servervm'
runuser -l mira -c 'ssh -p 2222 -o BatchMode=yes meshremote@servervm true'
```

---

## Question 17 - Rsync Transfer (servervm) - 4 pts

```bash
runuser -l mira -c 'rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@servervm:/home/meshremote/inbox/report.txt'
```

---

## Question 18 - Passwordless SSH (servervm) - 4 pts

```bash
# Run on servervm
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
install -d -m 0755 -o meshremote -g meshremote /home/meshremote/inbox
runuser -l mira -c 'ssh-copy-id -p 2222 meshremote@servervm'
runuser -l mira -c 'ssh -p 2222 -o BatchMode=yes meshremote@servervm true'
```

---

## Question 19 - Rsync Transfer (servervm) - 4 pts

```bash
runuser -l mira -c 'rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@servervm:/home/meshremote/inbox/report.txt'
```

---

## Question 20 - Passwordless SSH (servervm) - 4 pts

```bash
runuser -l mira -c 'ssh-copy-id -p 2222 meshremote@servervm'
runuser -l mira -c 'ssh -p 2222 -o BatchMode=yes meshremote@servervm true'
```

---

## Question 21 - Rsync Transfer (servervm) - 4 pts

```bash
runuser -l mira -c 'rsync -e "ssh -p 2222" /home/mira/report.txt meshremote@servervm:/home/meshremote/inbox/report.txt'
```

---

## Question 22 - Find And Copy (clientvm) - 4 pts

```bash
find /opt/exam-b/find -type f -user mira -mtime -1 -exec cp --parents {} /root/mira-files \;
```

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.exam-b.lab' && grep -Fqx '192.168.122.3 registry.exam-b.lab' /etc/hosts
grep -Eq '^server servervm iburst$' /etc/chrony.conf && systemctl is-enabled chronyd | grep -qx enabled && ssh admin@servervm sudo grep -Eq '^allow 192\.168\.122\.0/24$' /etc/chrony.conf && ssh admin@servervm sudo systemctl is-enabled chronyd | grep -qx enabled
useradd -D | grep -Eq 'INACTIVE=20' && getent passwd cato421 | awk -F: '{print $3":"$6}' | grep -qx '4421:' && chage -l jonas | grep -Eq 'Maximum.*45' && grep -Eq '^minlen\s*=\s*12$' /etc/security/pwquality.conf.d/coremesh.conf && grep -Eq '^minclass\s*=\s*3$' /etc/security/pwquality.conf.d/coremesh.conf && grep -Eq '^mira .*NOPASSWD: /usr/bin/systemctl restart firewalld$' /etc/sudoers.d/mira-firewalld
ssh admin@servervm sudo grep -Eq '^Port 2222$' /etc/ssh/sshd_config && ssh admin@servervm sudo firewall-cmd --list-rich-rules | grep -Fq 'port port="2222" protocol="tcp" accept' && runuser -l mira -c 'ssh -p 2222 -o BatchMode=yes meshremote@servervm true' && ssh admin@servervm test -f /home/meshremote/inbox/report.txt
test -f /root/mira-files/opt/exam-b/find/a/file1.txt && grep -q 'proto' /root/proto-lines && test -f /root/usr-local-b.tar.bz2 && /usr/local/bin/corecheck >/dev/null && test -s /root/coremesh-units.txt
swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewb" && $2=="reviewvgb" && $3>=299 && $3<=301{f=1} END{exit !f}' && tuned-adm active | grep -Eq 'virtual-guest|throughput-performance'
```
