# Processes, Logs, Targets, And Tuning - Exam Solution
Scenario ID: processes-logs-tuning
Mode: Exam
Time limit: 60 minutes
Objectives: processes-logs-tuning

Practice RHCSA v9 process control, persistent logging, systemd targets, and performance tuning.

## Task 01 - Busy Process Priority (clientvm) - 10 pts
```bash
PID=$(pgrep -n -f 'yes >/dev/null')
renice 10 -p "$PID"
```

## Task 02 - Persistent Journal (clientvm) - 10 pts
```bash
mkdir -p /var/log/journal
sed -i '/^Storage=/d' /etc/systemd/journald.conf
echo 'Storage=persistent' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
```

## Task 03 - Throughput Performance Profile (clientvm) - 10 pts
```bash
tuned-adm profile throughput-performance
tuned-adm active
```

## Task 04 - Note Service (clientvm) - 10 pts
```bash
systemctl enable --now rhcsa-note.service
```

## Task 05 - Default Boot Target (clientvm) - 10 pts
```bash
systemctl set-default multi-user.target
```
