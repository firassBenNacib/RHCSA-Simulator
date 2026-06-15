# Lab 03: DNF Repository Configuration

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-03-dnf-repositories` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 40 minutes |
| Objectives | software-scheduling-time |

Configure offline BaseOS and AppStream repositories on both systems.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client Repositories (client) - 10 pts

```bash
vim /etc/yum.repos.d/rhcsa.repo
[rhcsa-baseos]
name=RHCSA BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa-appstream]
name=RHCSA AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
```

---

## Task 02 - Server Repositories (server) - 10 pts

```bash
# Run on server
vim /etc/yum.repos.d/rhcsa.repo
[rhcsa-baseos]
name=RHCSA BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0
[rhcsa-appstream]
name=RHCSA AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
```
