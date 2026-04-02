# Lab 12: Find And Copy With Structure Solution

## Task 01 - Find all files owned by natfind and modified in the (clientvm) - 10 pts

```bash
find /opt/lab12/source -type f -user natfind -mtime -1 -exec cp --parents {} /root/natfind-files \;
```

## Task 02 - Copy them to /root/natfind-files and preserve the (clientvm) - 10 pts

```bash
find /root/natfind-files -type f | sort
```

## Verification

```bash
diff -u <(find /opt/lab12/source -type f -user natfind -mtime -1 | sed 's#^/opt/lab12/source#/root/natfind-files#' | sort) <(find /root/natfind-files -type f | sort)
```
