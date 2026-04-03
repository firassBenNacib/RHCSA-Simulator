# Lab 05: Users Groups And Sudo

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-05-users-groups-sudo` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | users-sudo-ssh |

Create local users on servervm with minimal useradd usage and delegated sudo rules.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create opsrune and the required users on servervm (servervm) - 10 pts

```bash
groupadd opsrune
useradd -G opsrune brenor
useradd -G opsrune lyessa
useradd quillan
useradd -M -s /sbin/nologin sarahx
```

---

## Task 02 - Set the interactive user passwords to cinder9 (clientvm) - 10 pts

```bash
printf 'brenor:cinder9
lyessa:cinder9
quillan:cinder9
' | chpasswd
```

---

## Task 03 - Create the required sudo rules on servervm (servervm) - 10 pts

```bash
printf '%%opsrune ALL=(root) /usr/sbin/useradd
' > /etc/sudoers.d/opsrune
visudo -f /etc/sudoers.d/opsrune -c
printf 'brenor ALL=(root) NOPASSWD: /usr/bin/passwd
' > /etc/sudoers.d/brenor-passwd
visudo -f /etc/sudoers.d/brenor-passwd -c
```

---

## Verification
```bash
ssh admin@servervm id -nG brenor | tr ' ' '\n' | grep -qx opsrune && ssh admin@servervm getent passwd brenor >/dev/null
ssh admin@servervm id -nG lyessa | tr ' ' '\n' | grep -qx opsrune && ssh admin@servervm getent passwd lyessa >/dev/null
ssh admin@servervm getent passwd sarahx | awk -F: '{exit !($6=="/nonexistent" || $6=="/" || $6=="")}' && ssh admin@servervm getent passwd sarahx | awk -F: '{exit !($7=="/sbin/nologin")}'
ssh admin@servervm sudo visudo -cf /etc/sudoers.d/opsrune >/dev/null && ssh admin@servervm sudo grep -Eq '^%opsrune[[:space:]]+ALL=\(root\)[[:space:]]+/usr/sbin/useradd[[:space:]]*$' /etc/sudoers.d/opsrune
ssh admin@servervm sudo visudo -cf /etc/sudoers.d/brenor-passwd >/dev/null && ssh admin@servervm sudo grep -Eq '^brenor[[:space:]]+ALL=\(root\)[[:space:]]+NOPASSWD:[[:space:]]+/usr/bin/passwd[[:space:]]*$' /etc/sudoers.d/brenor-passwd
```
