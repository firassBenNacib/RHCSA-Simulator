# Lab 27: At Job Scheduling Solution

## Task 01 - Create the user queue27 and set its password to (clientvm) - 10 pts

```bash
useradd -m queue27
passwd queue27
# enter: cinder9
```

## Task 02 - Enable and start the atd service (clientvm) - 10 pts

```bash
systemctl enable --now atd
```

## Task 03 - schedule a one-time at job that appends the text (clientvm) - 10 pts

```bash
runuser -l queue27 -c "echo 'echo AT27 OK >> /home/queue27/at27.log' | at now + 2 minutes"
atq
```

## Verification

```bash
systemctl is-enabled atd | grep -qx enabled
systemctl is-active atd | grep -qx active
atq | grep -q queue27
```
