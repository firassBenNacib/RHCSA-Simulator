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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client Repositories (clientvm) - 10 pts

On clientvm, configure a persistent repository file with the following settings:

- **BaseOS:** http://servervm/repo/BaseOS/
- **AppStream:** http://servervm/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Task 02 - Server Repositories (servervm) - 10 pts

On servervm, configure the same repository file with the same settings.

---

## Task 03 - Verify Repositories (clientvm) - 10 pts

Verify that both repositories are available on both systems.

## Hints
- You can use one repo file per system.
- Use vim to type the repository file manually.

## Validation Commands
```bash
dnf repolist | grep -Eq 'rhcsa-baseos|BaseOS' && dnf repolist | grep -Eq 'rhcsa-appstream|AppStream'
ssh admin@servervm sudo dnf repolist | grep -Eq 'rhcsa-baseos|BaseOS' && ssh admin@servervm sudo dnf repolist | grep -Eq 'rhcsa-appstream|AppStream'
```
