# RHCSA 10 Lab 45: Secure Copy

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-45-secure-copy` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Securely transfer files between systems.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /root/rhcsa10-transfer.txt containing TRANSFER10 (client) - 10 pts

```bash
echo TRANSFER10 > /root/rhcsa10-transfer.txt
```

---

## Task 02 - Copy the file to server:/root/rhcsa10-transfer.txt (client + server) - 20 pts

```bash
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C rhcsa10-transfer >/dev/null 2>&1
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 /root/rhcsa10-transfer.txt root@server:/root/rhcsa10-transfer.txt
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/id_ed25519 root@server 'cat /root/rhcsa10-transfer.txt'
```
