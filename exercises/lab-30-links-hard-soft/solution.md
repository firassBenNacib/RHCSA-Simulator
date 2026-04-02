# Lab 30: Hard And Soft Links Solution

## Task 01 - Create the file /root/linksource30 containing the (clientvm) - 10 pts

```bash
printf 'link-test
' > /root/linksource30
```

## Task 02 - Create the hard link /root/linkhard30 and the (clientvm) - 10 pts

```bash
ln /root/linksource30 /root/linkhard30
ln -s /root/linksource30 /root/linksoft30
```

## Verification

```bash
test "$(stat -c '%i' /root/linksource30)" = "$(stat -c '%i' /root/linkhard30)" && test "$(stat -c '%h' /root/linksource30)" -ge 2
test "$(readlink -f /root/linksoft30)" = '/root/linksource30' && grep -Fqx 'link-test' /root/linksource30
```
