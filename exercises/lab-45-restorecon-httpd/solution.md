# Lab 45: Restore Default SELinux Context Solution

## Task 01 - the file /var/www/html/index45.html has the wrong (clientvm) - 10 pts

```bash
restorecon -v /var/www/html/index45.html
```

## Task 02 - Ensure the httpd service is enabled and running (clientvm) - 10 pts

```bash
systemctl enable --now httpd
getenforce
ls -Z /var/www/html/index45.html
```

## Verification

```bash
getenforce | grep -qx Enforcing
matchpathcon /var/www/html/index45.html | grep -Eq ':httpd_sys_content_t:' && ls -Z /var/www/html/index45.html | grep -Eq ':httpd_sys_content_t:'
systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active
```
