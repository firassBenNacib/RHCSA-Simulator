# RHCSA 10 Lab 45: Secure Copy

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-45-secure-copy` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Securely transfer files between systems.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /root/rhcsa10-transfer.txt containing TRANSFER10 (server) - 10 pts

```bash
echo TRANSFER10 > /root/rhcsa10-transfer.txt
```

---

## Task 02 - Copy the file to server:/root/rhcsa10-transfer.txt (server) - 10 pts

```bash
scp /root/rhcsa10-transfer.txt root@server:/root/rhcsa10-transfer.txt
```

---

## Task 03 - Verify the file exists on server (server) - 10 pts

```bash
ssh root@server 'cat /root/rhcsa10-transfer.txt'
```
