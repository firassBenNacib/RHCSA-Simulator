# Lab 05: Users Groups And Sudo

## Lab Tasks
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

On servervm, create the group opsrune and the users brenor, lyessa, and quillan. Create brenor and lyessa with opsrune as a supplementary group at creation time. Create sarahx without a home directory and with the shell /sbin/nologin.

---

## Task 02 - Set the interactive user passwords to cinder9 (clientvm) - 10 pts

Set the passwords of brenor, lyessa, and quillan to cinder9.

---

## Task 03 - Create the required sudo rules on servervm (servervm) - 10 pts

On servervm, allow members of opsrune to run /usr/sbin/useradd through sudo, and allow brenor to run /usr/bin/passwd for other users without a sudo password prompt.

## Hints
- Use useradd -G when the supplementary group is known at account creation time.
- Keep sudo rules in /etc/sudoers.d/ and validate each drop-in with visudo -f.

## Validation Commands
```bash
ssh admin@servervm id -nG brenor | tr ' ' '\n' | grep -qx opsrune && ssh admin@servervm getent passwd brenor >/dev/null
ssh admin@servervm id -nG lyessa | tr ' ' '\n' | grep -qx opsrune && ssh admin@servervm getent passwd lyessa >/dev/null
ssh admin@servervm getent passwd sarahx | awk -F: '{exit !($6=="/nonexistent" || $6=="/" || $6=="")}' && ssh admin@servervm getent passwd sarahx | awk -F: '{exit !($7=="/sbin/nologin")}'
ssh admin@servervm sudo visudo -cf /etc/sudoers.d/opsrune >/dev/null && ssh admin@servervm sudo grep -Eq '^%opsrune[[:space:]]+ALL=\(root\)[[:space:]]+/usr/sbin/useradd[[:space:]]*$' /etc/sudoers.d/opsrune
ssh admin@servervm sudo visudo -cf /etc/sudoers.d/brenor-passwd >/dev/null && ssh admin@servervm sudo grep -Eq '^brenor[[:space:]]+ALL=\(root\)[[:space:]]+NOPASSWD:[[:space:]]+/usr/bin/passwd[[:space:]]*$' /etc/sudoers.d/brenor-passwd
```
