# Lab 39: SSH Key Authentication and Rsync

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-ssh-key-rsync` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh, nfs-and-autofs |

Configure key-based SSH access and securely transfer files between systems.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Create the user mesh39 on both clientvm and servervm.…
**System:** clientvm

Create the user mesh39 on both clientvm and servervm. Set the password on both systems to cinder9.

---

### Task 02 - generate an ED25519 SSH key pair with no passphrase
**System:** clientvm

As user mesh39 on clientvm, generate an ED25519 SSH key pair with no passphrase.

---

### Task 03 - Configure passwordless SSH access for mesh39 from…
**System:** clientvm

Configure passwordless SSH access for mesh39 from clientvm to servervm using public key authentication.

---

### Task 04 - Using rsync over SSH, copy the directory…
**System:** servervm

Using rsync over SSH, copy the directory /home/mesh39/client-data/ from clientvm to /home/mesh39/server-data/ on servervm.

### Hints
- Use the mesh39 account for the SSH key work.
- Verify the transfer by checking the copied file on servervm through SSH.

### Validation Commands
```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=no mesh39@192.168.122.3 "test -f /home/mesh39/server-data/file1.txt"
```
