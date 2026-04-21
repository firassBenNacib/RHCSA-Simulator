#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id worker42 >/dev/null 2>&1 || useradd -m worker42
echo 'worker42:cinder9' | chpasswd
pkill -u worker42 -f 'while :; do :; done' >/dev/null 2>&1 || true
pkill -u worker42 -f 'sleep 7200' >/dev/null 2>&1 || true
# Seed a low-priority CPU-bound process so the lab stays responsive during checks.
runuser -l worker42 -c 'nohup nice -n 19 bash -c "while :; do :; done" >/dev/null 2>&1 & echo $! > ~/cpu.pid'
runuser -l worker42 -c 'nohup sleep 7200 >/dev/null 2>&1 & echo $! > ~/sleep.pid'
