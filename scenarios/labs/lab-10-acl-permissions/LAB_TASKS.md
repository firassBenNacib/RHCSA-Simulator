# Lab 10: ACL And Permissions

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-10-acl-permissions` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms |

Apply fine grained access with POSIX ACLs.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Copy /etc/fstab to /var/tmp/fstab-acl
**System:** clientvm

Copy /etc/fstab to /var/tmp/fstab-acl.

---

### Task 02 - Set owner and group to root:root, remove all execute…
**System:** clientvm

- **Set owner and group to root:** root, remove all execute bits, give natacl read-write, deny haracl all access, and allow others read only.

### Hints
- Create the users natacl and haracl if they are missing.
- Use setfacl for the named user entries.

### Validation Commands
```bash
getfacl /var/tmp/fstab-acl
ls -l /var/tmp/fstab-acl
```
