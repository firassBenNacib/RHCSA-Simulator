# Lab 31: Shell Loop Script Solution

## Task 01 - Create an executable script (clientvm) - 10 pts

```bash
vim /usr/local/bin/listlogs31
#!/bin/bash
for item in /opt/lab31/*; do
    if [[ "$item" == *.log ]]; then
        echo "$item" >> /root/listlogs31.out
    fi
done
chmod +x /usr/local/bin/listlogs31
```

## Task 02 - Run the script once (clientvm) - 10 pts

```bash
/usr/local/bin/listlogs31
```

## Verification

```bash
diff -u <(find /opt/lab31 -maxdepth 1 -type f -name '*.log' | sort) <(sort /root/listlogs31.out)
```
