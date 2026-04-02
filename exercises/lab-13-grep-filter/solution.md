# Lab 13: Text Filtering With Grep Solution

## Task 01 - From /usr/share/dict/words, extract the lines (clientvm) - 10 pts

```bash
grep "ich" /usr/share/dict/words > /root/lines
```

## Verification

```bash
test -s /root/lines && grep -q 'ich' /root/lines && ! awk 'index($0,"ich")==0{print; exit 1}' /root/lines
```
