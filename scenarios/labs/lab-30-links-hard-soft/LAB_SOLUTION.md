# Lab 30: Hard And Soft Links

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-30-links-hard-soft` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Create and verify both a hard link and a symbolic link to the same source file.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the file /root/linksource30 containing the (clientvm) - 10 pts

```bash
echo 'link-test' > /root/linksource30
```

---

## Task 02 - Create the hard link /root/linkhard30 and the (clientvm) - 10 pts

```bash
ln /root/linksource30 /root/linkhard30
ln -s /root/linksource30 /root/linksoft30
```
