# RHCSA 10 Lab 04: RPM Repositories

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-04-rpm-repositories` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 35 minutes |
| Objectives | software-management |

Configure BaseOS and AppStream repositories.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure a persistent BaseOS repository (client) - 10 pts

On client, configure a persistent BaseOS repository. BaseOS URL: http://server/repo/BaseOS/.

---

## Task 02 - Configure a persistent AppStream repository (client) - 10 pts

On client, configure a persistent AppStream repository. AppStream URL: http://server/repo/AppStream/.

---

## Task 03 - Disable GPG checks for both RHCSA10 repositories and verify both (client) - 10 pts

On client, disable GPG checks for both RHCSA10 repositories and verify both repositories are enabled.

---

## Task 04 - Configure BaseOS and AppStream repositories (server) - 10 pts

On server, configure matching BaseOS and AppStream repositories with GPG checks disabled.
