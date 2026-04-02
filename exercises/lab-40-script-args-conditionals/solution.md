# Lab 40: Script Arguments and Conditionals Solution

## Task 01 - Create the executable script (clientvm) - 10 pts

```bash
vim /usr/local/bin/usercheck40
```

## Task 02 - The script must accept one username argument (clientvm) - 10 pts

```bash
#!/bin/bash
user_name="$1"
```

## Task 03 - If the user exists, print EXISTS: username to (clientvm) - 10 pts

```bash
if id "$user_name" >/dev/null 2>&1; then
  echo "EXISTS: $user_name"
  exit 0
else
  echo "MISSING: $user_name"
  exit 1
fi
```

## Task 04 - If the user does not exist, print MISSING: username (clientvm) - 10 pts

```bash
:wq
chmod 755 /usr/local/bin/usercheck40
```

## Verification

```bash
id script40 >/dev/null 2>&1
/usr/local/bin/usercheck40 script40 | grep -qx 'EXISTS: script40'
output="$(/usr/local/bin/usercheck40 nosuch40 2>/dev/null || true)"; test "$output" = 'MISSING: nosuch40'
```
