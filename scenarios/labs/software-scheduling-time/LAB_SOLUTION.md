# Scheduling, Services, And Time Sync - Lab Solution
Scenario ID: software-scheduling-time
Mode: Lab
Time limit: 75 minutes
Objectives: software-scheduling-time

Practice RHCSA v9 time synchronization, service control, cron, at, and persistent service enablement.

## Task 01 - Chrony Client (clientvm) - 10 pts
```bash
sed -i '/^server /d;/^pool /d' /etc/chrony.conf
echo 'server servervm iburst' >> /etc/chrony.conf
systemctl enable --now chronyd
```

## Task 02 - Schedule Note Service (clientvm) - 10 pts
```bash
systemctl enable --now schedule-note.service
```

## Task 03 - Local Schedule Page (clientvm) - 10 pts
```bash
systemctl enable --now httpd
curl http://localhost/schedule/index.html
```

## Task 04 - Root Cron Job (clientvm) - 10 pts
```bash
(crontab -l 2>/dev/null; echo '0 * * * * /bin/date >> /var/log/rhcsa-cron.log') | crontab -
```

## Task 05 - One-Time At Job (clientvm) - 10 pts
```bash
systemctl enable --now atd
echo 'echo RHCSA > /root/at-job.txt' | at now + 5 minutes
atq
```

Verification
```bash
chronyc sources -v
systemctl status schedule-note.service --no-pager
systemctl is-enabled httpd
curl http://localhost/schedule/index.html
crontab -l
atq
```
