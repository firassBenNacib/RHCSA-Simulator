# Lab 11: Time Synchronization Solution

## Task 01 - Configure chrony on clientvm so it synchronizes (clientvm) - 10 pts

```bash
vim /etc/chrony.conf
server servervm iburst
# remove any other server or pool lines
systemctl enable --now chronyd
chronyc sources -v
```

## Verification

```bash
awk '$1 ~ /^(server|pool)$/ { if ($2 != "servervm") bad=1; if ($1=="server" && $2=="servervm") good=1 } END { exit !(good && !bad) }' /etc/chrony.conf
systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active
```
