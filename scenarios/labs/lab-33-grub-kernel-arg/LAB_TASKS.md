# Lab 33: Bootloader Kernel Argument

## Lab Tasks
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

Configure the bootloader on clientvm so that every installed kernel boots with the kernel argument audit=1.

---

## Task 02 — Part 02
**System:** clientvm

The change must persist across reboots and must not require manual GRUB editing during startup.

### Hints
- Use a persistent bootloader tool rather than a one-time edit at the GRUB menu.
- Verify the configured kernel arguments for all installed kernels.

### Checks
```bash
grubby --info=ALL | grep -E "^args=" | grep -q "audit=1"
```
