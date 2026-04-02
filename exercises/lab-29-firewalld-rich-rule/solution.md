# Lab 29: Firewalld Rich Rule Solution

## Task 01 - Configure a persistent firewalld rich rule that (clientvm) - 10 pts

```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

## Task 02 - Reload firewalld and verify that the rule is active (clientvm) - 10 pts

```bash
firewall-cmd --list-rich-rules
```

## Verification

```bash
firewall-cmd --list-rich-rules | grep -Fq 'source address="192.168.122.0/24"' && firewall-cmd --list-rich-rules | grep -Fq 'port port="2222" protocol="tcp" accept'
```
