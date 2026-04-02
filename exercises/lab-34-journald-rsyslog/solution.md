# Lab 34: Journald Persistence and Rsyslog Solution

## Task 01 - Configure journald on clientvm so logs are stored (clientvm) - 10 pts

```bash
mkdir -p /var/log/journal
vim /etc/systemd/journald.conf
# Set: Storage=persistent
:wq
systemctl restart systemd-journald
```

## Task 02 - Create the drop-in file (clientvm) - 10 pts

```bash
vim /etc/rsyslog.d/10-auth34.conf
authpriv.warning    /var/log/auth34.log
:wq
```

## Task 03 - Ensure the rsyslog service is active after your (clientvm) - 10 pts

```bash
systemctl restart rsyslog
systemctl enable rsyslog
```

## Verification

```bash
test -d /var/log/journal && grep -Eq '^[[:space:]]*Storage[[:space:]]*=[[:space:]]*persistent[[:space:]]*$' /etc/systemd/journald.conf
grep -Eq '^[[:space:]]*authpriv\.warning[[:space:]]+/var/log/auth34\.log[[:space:]]*$' /etc/rsyslog.d/10-auth34.conf
systemctl is-active rsyslog | grep -qx active
```
