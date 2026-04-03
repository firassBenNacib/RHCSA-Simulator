# Lab 33: Bootloader Kernel Argument

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-33-grub-kernel-arg` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | boot-and-recovery |

Modify the system bootloader so every installed kernel boots with the required persistent argument.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure the bootloader on clientvm so that every (clientvm) - 10 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

---

## Task 02 - The change must persist across reboots and must not (clientvm) - 10 pts

```bash
grubby --info=ALL | grep -E "^kernel|^args"
```
