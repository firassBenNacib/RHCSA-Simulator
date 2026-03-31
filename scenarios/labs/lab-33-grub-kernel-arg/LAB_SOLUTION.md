# Lab 33: Bootloader Kernel Argument

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-33-grub-kernel-arg` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | boot-and-recovery, system-services-and-targets |

Modify the system bootloader so every installed kernel boots with the required persistent argument.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
grubby --update-kernel=ALL --args="audit=1"
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
grubby --info=ALL | grep -E "^kernel|^args"
```

---

### Verification
```bash
grubby --info=ALL | grep -E "^args=" | grep -q "audit=1"
```
