# RHCSA 10 Lab 07: Flatpak Package

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-07-flatpak-package` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | software-management |

Install and remove Flatpak applications from a configured remote.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure the system Flatpak remote rhcsa10 exists and points to file:///op (client) - 10 pts

```bash
flatpak remote-add --system --if-not-exists --no-gpg-verify rhcsa10 file:///opt/rhcsa/flatpak/repo
```

---

## Task 02 - Install Flatpak application org.rhcsa.Tools from rhcsa10 for the system (client) - 10 pts

```bash
flatpak install --system -y rhcsa10 org.rhcsa.Tools
```

---

## Task 03 - Remove org.rhcsa.Tools and verify that it is no longer installed (client) - 10 pts

```bash
flatpak uninstall --system -y org.rhcsa.Tools
touch /root/org.rhcsa.Tools.removed
```
