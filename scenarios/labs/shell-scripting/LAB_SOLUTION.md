# Shell Scripting Basics - Lab Solution
Scenario ID: shell-scripting
Mode: Lab
Time limit: 45 minutes
Objectives: shell-scripting

Practice RHCSA v9 shell scripting with loops, conditionals, command substitution, and executable scripts.

## Task 01 - User Creation Script (clientvm) - 15 pts
```bash
cat > /usr/local/bin/rhcsa-user-summary <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
input=/opt/rhcsa/workspaces/shell-scripting/users.csv
created=0
existing=0
while IFS= read -r user; do
  [[ -z "$user" ]] && continue
  if id "$user" >/dev/null 2>&1; then
    existing=$((existing + 1))
  else
    useradd "$user"
    created=$((created + 1))
  fi
done < "$input"
printf 'created=%s
existing=%s
' "$created" "$existing" > /root/user-summary.txt
EOF
chmod +x /usr/local/bin/rhcsa-user-summary
```

## Task 02 - User Summary Output (clientvm) - 10 pts
```bash
/usr/local/bin/rhcsa-user-summary
cat /root/user-summary.txt
```

## Task 03 - Service Check Script (clientvm) - 15 pts
```bash
cat > /usr/local/bin/rhcsa-service-check <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
input=/opt/rhcsa/workspaces/shell-scripting/services.txt
: > /root/service-status.txt
while IFS= read -r service; do
  [[ -z "$service" ]] && continue
  state=$(systemctl is-active "$service" 2>/dev/null || true)
  [[ "$state" == "active" ]] || state=inactive
  printf '%s:%s
' "$service" "$state" >> /root/service-status.txt
done < "$input"
EOF
chmod +x /usr/local/bin/rhcsa-service-check
```

## Task 04 - Execute The Scripts (clientvm) - 10 pts
```bash
/usr/local/bin/rhcsa-user-summary
/usr/local/bin/rhcsa-service-check
```

Verification
```bash
ls -l /usr/local/bin/rhcsa-user-summary /usr/local/bin/rhcsa-service-check
cat /root/user-summary.txt
cat /root/service-status.txt
getent passwd training1 training2 training3
```
