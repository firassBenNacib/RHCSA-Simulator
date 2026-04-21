# Lab 49: Flatpak Remote Setup

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-49-flatpak-remote` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-management |

Configure Flatpak system repository access for RHCSA 10 practice.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Install Flatpak (client) - 10 pts

```bash
dnf install -y flatpak
```

---

## Task 02 - Add the local Flatpak remote (client) - 10 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify rhcsa-lab file:///opt/rhcsa/flatpak/repo
```

---

## Task 03 - Verify the system remote (client) - 10 pts

```bash
flatpak remotes --system --columns=name,url
```
