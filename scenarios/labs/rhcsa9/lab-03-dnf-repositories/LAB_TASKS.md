# Lab 03: DNF Repository Configuration

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-03-dnf-repositories` |
| Mode | Lab |
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

On client, configure a persistent repository file with the following settings:

- **BaseOS:** http://server/repo/BaseOS/
- **AppStream:** http://server/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Task 02 - Server Repositories (server) - 10 pts

On server, configure the same repository file with the same settings.

---

## Task 03 - Verify Repositories (client) - 10 pts

Verify that both repositories are available on both systems.
