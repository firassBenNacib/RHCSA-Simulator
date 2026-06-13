#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

# --- Reset repos on server ---
mkdir -p /root/.repo-backup-server-exam-h
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-h


# --- Exam H server role cleanup ---
hostnamectl set-hostname server
rhcsa_remove_matching_lines 'clienth.exam10.lab' /etc/hosts
rm -f /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf /etc/systemd/journald.conf.d/persistent.conf
rm -rf /var/log/journal
rm -f /etc/rsyslog.d/examh-local6.conf /var/log/examh-local6.log
firewall-cmd --permanent --remove-port=2208/tcp >/dev/null 2>&1 || true
firewall-cmd --remove-port=2208/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
# --- NFS cleanup ---
rm -f /etc/exports.d/exam-h.exports /etc/exports.d/exam-h-integrated.exports
exportfs -ar >/dev/null 2>&1 || true
