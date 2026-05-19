#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id worker42 >/dev/null 2>&1 || useradd -m worker42
echo 'worker42:cinder9' | chpasswd
pkill -u worker42 -f 'rhcsa42-cpu' >/dev/null 2>&1 || true
pkill -u worker42 -f 'while :; do :; done' >/dev/null 2>&1 || true
pkill -u worker42 -f 'sleep 7200' >/dev/null 2>&1 || true
cat > /home/worker42/rhcsa42-cpu.sh <<'EOF'
#!/usr/bin/env bash
while :; do :; done
EOF
chown worker42:worker42 /home/worker42/rhcsa42-cpu.sh
chmod 0755 /home/worker42/rhcsa42-cpu.sh
# Seed a low-priority CPU-bound process so the lab stays responsive during checks.
runuser -u worker42 -- bash -c 'nohup nice -n 19 /home/worker42/rhcsa42-cpu.sh >/dev/null 2>&1 & echo $! > /home/worker42/cpu.pid'
runuser -u worker42 -- bash -c 'nohup sleep 7200 >/dev/null 2>&1 & echo $! > /home/worker42/sleep.pid'
chown worker42:worker42 /home/worker42/cpu.pid /home/worker42/sleep.pid
