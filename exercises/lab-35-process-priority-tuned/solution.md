# Lab 35: Process Priority and Tuned Solution

## Task 01 - Install the tuned package if it is not already (clientvm) - 10 pts

```bash
dnf install -y tuned
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

## Task 02 - Start the command sleep 3600 in the background and (clientvm) - 10 pts

```bash
sleep 3600 &
echo $! > /root/sleep35.pid
```

## Task 03 - Adjust the nice value of that process so it becomes 5 (clientvm) - 10 pts

```bash
renice 5 -p "$(cat /root/sleep35.pid)"
```

## Verification

```bash
tuned-adm active | grep -q throughput-performance
test -f /root/sleep35.pid
ps -o ni= -p "$(cat /root/sleep35.pid)" | tr -d " " | grep -qx 5
```
