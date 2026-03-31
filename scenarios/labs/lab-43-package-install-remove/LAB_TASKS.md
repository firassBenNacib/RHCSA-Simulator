# Lab 43: Package Install And Remove

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-43-package-install-remove` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | repositories-and-packages |

Install packages from the prepared local repositories and remove the one that is no longer needed.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Use the prepared local repositories on clientvm to…
**System:** clientvm

Use the prepared local repositories on clientvm to install the packages tree and dos2unix.

---

### Task 02 — Remove dos2unix and leave tree installed
**System:** clientvm

Remove dos2unix and leave tree installed.

### Hints
- The repositories are already defined for this lab. Focus on package management.

### Validation Commands
```bash
rpm -q tree
! rpm -q dos2unix
```
