# Lab 49: Flatpak Remote Setup

## Lab Tasks
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

Install the flatpak package if it is not already installed.

---

## Task 02 - Add the local Flatpak remote (client) - 10 pts

Configure a system Flatpak remote named rhcsa-lab that points to file:///opt/rhcsa/flatpak/repo with GPG verification disabled.

---

## Task 03 - Verify the system remote (client) - 10 pts

Verify that the remote is visible to the system Flatpak installation.
