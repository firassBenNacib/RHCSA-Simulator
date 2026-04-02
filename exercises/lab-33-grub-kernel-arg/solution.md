# Lab 33: Bootloader Kernel Argument Solution

## Task 01 - Configure the bootloader on clientvm so that every (clientvm) - 10 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

## Task 02 - The change must persist across reboots and must not (clientvm) - 10 pts

```bash
grubby --info=ALL | grep -E "^kernel|^args"
```

## Verification

```bash
grubby --info=ALL | grep -E "^args=" | grep -q "audit_backlog_limit=8192"
```
