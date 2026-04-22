# RHCSA 10 Lab 04: RPM Repositories

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-04-rpm-repositories` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | software-management |

Configure BaseOS and AppStream repositories.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure a persistent BaseOS repository using http://server/repo/BaseOS (server) - 10 pts

```bash
cat > /etc/yum.repos.d/rhcsa10.repo <<'EOF'
[rhcsa10-baseos]
name=RHCSA10 BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa10-appstream]
name=RHCSA10 AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
```

---

## Task 02 - Configure a persistent AppStream repository using http://server/repo/App (server) - 10 pts

```bash
dnf clean all
```

---

## Task 03 - Disable GPG checks and verify both repositories are enabled (server) - 10 pts

```bash
dnf repolist --enabled
```
