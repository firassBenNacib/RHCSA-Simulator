# Lab 04: SELinux Custom HTTP Port Solution

## Task 01 - Configure Apache on clientvm so it listens on TCP (clientvm) - 10 pts

```bash
vim /etc/httpd/conf/httpd.conf
Listen 9082
systemctl enable --now httpd
```

## Task 02 - Allow TCP port 9082 through the firewall permanently (clientvm) - 10 pts

```bash
firewall-cmd --permanent --add-port=9082/tcp
firewall-cmd --reload
```

## Task 03 - Make the SELinux changes needed so Apache serves (clientvm) - 10 pts

```bash
semanage port -a -t http_port_t -p tcp 9082
systemctl restart httpd
```

## Verification

```bash
ss -ltn '( sport = :9082 )' | grep -q ':9082' && systemctl is-enabled httpd | grep -qx enabled && systemctl is-active httpd | grep -qx active
firewall-cmd --permanent --query-port=9082/tcp
curl -fsS http://localhost:9082 >/dev/null && semanage port -l | grep -Eq '^http_port_t\b.*\b9082\b'
```
