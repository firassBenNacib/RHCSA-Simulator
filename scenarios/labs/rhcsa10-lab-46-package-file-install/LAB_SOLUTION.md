# RHCSA 10 Lab 46: Local RPM Install

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-46-package-file-install` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-management |

Install software from a local RPM file.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Find an RPM named tree under /var/www/html/repo or the mounted ISO (client) - 10 pts

```bash
rpm_path=$(find /var/www/html/repo /mnt/rhcsa-bootstrap-iso -name 'tree-*.rpm' 2>/dev/null | head -n1)
test -n "$rpm_path"
```

---

## Task 02 - Install the local RPM file without enabling external repositories (client) - 10 pts

```bash
dnf install -y "$rpm_path"
```

---

## Task 03 - Verify that tree is installed (client) - 10 pts

```bash
rpm -q tree
```
