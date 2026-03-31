# Mock Exam C: Recovery And Automation - Exam Solution
Scenario ID: mock-exam-c
Mode: Exam
Time limit: 120 minutes
Objectives: boot-and-recovery, software-scheduling-time, shell-scripting, containers

A redesigned RHCSA v9 mock exam focused on password recovery, shell scripting, scheduling, and rootless container management.

## Task 01 - Boot Recovery (clientvm) - 20 pts
```bash
# Reboot clientvm and stop at the GRUB menu.
# Edit the active kernel entry, append rd.break, then boot with Ctrl+x.
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
exit
exit
# Let the relabel complete and log in normally as root with the new password.
systemctl get-default
```

## Task 02 - One-Time At Job (clientvm) - 15 pts
```bash
systemctl enable --now atd
echo 'echo automation window ready > /root/automation-at.txt' | at now + 5 minutes
atq
```

## Task 03 - Service Audit Script (clientvm) - 20 pts
```bash
cat > /usr/local/bin/service-audit <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
input=/opt/rhcsa/workspaces/automation/services.lst
: > /root/service-audit.txt
while IFS= read -r service; do
  [[ -z "$service" ]] && continue
  if systemctl list-unit-files --type=service --all | awk "{print \$1}" | grep -qx "${service}.service"; then
    state=$(systemctl is-active "$service" 2>/dev/null || true)
    [[ "$state" == "active" ]] || state=inactive
  else
    state=missing
  fi
  printf '%s:%s
' "$service" "$state" >> /root/service-audit.txt
done < "$input"
EOF
chmod +x /usr/local/bin/service-audit
/usr/local/bin/service-audit
```

## Task 04 - Root Cron Automation (clientvm) - 15 pts
```bash
(crontab -l 2>/dev/null | grep -v '/usr/local/bin/service-audit'; echo '12 * * * * /usr/local/bin/service-audit >> /var/log/service-audit.log') | crontab -
```

## Task 05 - Rootless Container Service (clientvm) - 30 pts
```bash
loginctl enable-linger admin
runuser -l admin -c 'podman image exists localhost/rhcsa-httpd-base:latest || podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar'
runuser -l admin -c 'podman build -t localhost/briefing-web:latest /opt/rhcsa/workspaces/automation-container'
runuser -l admin -c 'podman rm -f briefing-web >/dev/null 2>&1 || true'
runuser -l admin -c 'podman run -d --name briefing-web -p 8090:80 -v /opt/rhcsa/workspaces/automation-container/site-content:/var/www/html:Z localhost/briefing-web:latest'
runuser -l admin -c 'mkdir -p ~/.config/systemd/user && cd ~/.config/systemd/user && podman generate systemd --name briefing-web --files --new'
runuser -l admin -c 'systemctl --user daemon-reload'
runuser -l admin -c 'systemctl --user enable --now container-briefing-web.service'
```
