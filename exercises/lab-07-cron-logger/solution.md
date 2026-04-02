# Lab 07: Cron Scheduling Solution

## Task 01 - Create user ferro if it does not exist and set its (clientvm) - 10 pts

```bash
id ferro || useradd -m ferro
passwd ferro
# enter: cinder9
```

## Task 02 - Configure a cron job for ferro that runs every 2 (clientvm) - 10 pts

```bash
crontab -e -u ferro
*/2 * * * * logger "Lab 07 running"
systemctl enable --now crond
```

## Verification

```bash
crontab -l -u ferro | grep -Fqx '*/2 * * * * logger "Lab 07 running"'
systemctl is-enabled crond | grep -qx enabled && systemctl is-active crond | grep -qx active
```
