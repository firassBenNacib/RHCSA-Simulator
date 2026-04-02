# Lab 38: SELinux Boolean Solution

## Task 01 - configure the SELinux boolean (clientvm) - 10 pts

```bash
setsebool -P httpd_can_network_connect on
```

## Task 02 - SELinux must remain in enforcing mode (clientvm) - 10 pts

```bash
getenforce
getsebool httpd_can_network_connect
```

## Verification

```bash
getsebool httpd_can_network_connect | grep -q "--> on"
getenforce | grep -qx Enforcing
```
