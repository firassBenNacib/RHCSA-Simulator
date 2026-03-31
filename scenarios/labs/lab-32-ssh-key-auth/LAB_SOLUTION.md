# Lab 32: SSH Key Authentication

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-32-ssh-key-auth` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | users-sudo-ssh |

Configure passwordless SSH login from clientvm to servervm using a key pair.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm + servervm

#### Commands
```bash
useradd -m ops32
passwd ops32
# enter: redhat
# on servervm
useradd -m backup32
passwd backup32
# enter: redhat
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
runuser -l ops32 -c "ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa"
runuser -l ops32 -c "ssh-copy-id backup32@servervm"
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
runuser -l ops32 -c "ssh -o StrictHostKeyChecking=no backup32@servervm true"
```

---

### Verification
```bash
runuser -l ops32 -c "ssh -o StrictHostKeyChecking=no -o BatchMode=yes backup32@servervm true"
```
