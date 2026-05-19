# RHCSA 10 Lab 45: Secure Copy

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-45-secure-copy` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Securely transfer files between systems.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - create /root/rhcsa10-transfer.txt containing TRANSFER10 (client) - 10 pts

```bash
echo TRANSFER10 > /root/rhcsa10-transfer.txt
```

---

## Task 02 - copy the file to server:/root/rhcsa10-transfer.txt (client) - 20 pts

```bash
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/runtime_generated_ed25519 /root/rhcsa10-transfer.txt root@server:/root/rhcsa10-transfer.txt
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /root/.ssh/runtime_generated_ed25519 root@server 'cat /root/rhcsa10-transfer.txt'
```
