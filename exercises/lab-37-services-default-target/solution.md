# Lab 37: Services and Default Target Solution

## Task 01 - Configure clientvm to boot into multi-user.target (clientvm) - 10 pts

```bash
systemctl set-default multi-user.target
```

## Task 02 - Ensure the rsyslog service is enabled and running (clientvm) - 10 pts

```bash
systemctl enable --now rsyslog
```

## Task 03 - If postfix is installed, disable it and stop it (clientvm) - 10 pts

```bash
systemctl disable --now postfix
```

## Verification

```bash
systemctl get-default | grep -qx multi-user.target
systemctl is-enabled rsyslog | grep -qx enabled
systemctl is-active rsyslog | grep -qx active
```
