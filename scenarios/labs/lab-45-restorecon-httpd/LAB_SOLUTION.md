# Lab 45: Restore Default SELinux Context

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-45-restorecon-httpd` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms |

Restore the default SELinux context on existing web content without disabling SELinux.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - the file /var/www/html/index45.html has the wrong…
**System:** clientvm

#### Command Flow
```bash
restorecon -v /var/www/html/index45.html
```

---

### Task 02 - Ensure the httpd service is enabled and running.…
**System:** clientvm

#### Command Flow
```bash
systemctl enable --now httpd
getenforce
ls -Z /var/www/html/index45.html
```

---

### Verification
```bash
getenforce
ls -Z /var/www/html/index45.html
systemctl is-enabled httpd
```
