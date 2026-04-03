# Lab 45: Restore Default SELinux Context

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-45-restorecon-httpd` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | selinux-and-default-perms |

Restore the default SELinux context for a web file on servervm and keep httpd enforcing.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Restore the default context on servervm (servervm) - 15 pts

On servervm, the file /var/www/html/index45.html has the wrong SELinux context. Restore the default context.

---

## Task 02 - Enable httpd on servervm with SELinux enforcing (servervm) - 15 pts

Ensure the httpd service is enabled and running on servervm. SELinux must remain enforcing.

## Hints
- Use the default file-context policy instead of a custom override.
- This lab now runs on servervm.

## Validation Commands
```bash
ssh admin@servervm matchpathcon /var/www/html/index45.html | awk '{print $3}' | grep -qx httpd_sys_content_t
ssh admin@servervm getenforce | grep -qx Enforcing && ssh admin@servervm systemctl is-enabled httpd | grep -qx enabled && ssh admin@servervm systemctl is-active httpd | grep -qx active
```
