#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/root/.lab-backup"
VAGRANT_KEYS_BACKUP="${BACKUP_DIR}/vagrant.authorized_keys"
PENDING_MARKER="${BACKUP_DIR}/vagrant_restore_pending"

RESTORE_CORE="/usr/local/sbin/rhcsa-restore-vagrant-ssh.sh"
RESTORE_MANUAL="/usr/local/sbin/restore-vagrant-access.sh"
RECOVERY_TOGGLE="/usr/local/sbin/rhcsa-password-recovery-mode"

SSHD_DROPIN_DIR="/etc/systemd/system/sshd.service.d"
SSHD_DROPIN_FILE="${SSHD_DROPIN_DIR}/10-rhcsa-restore-vagrant.conf"

LOG_FILE="/var/log/rhcsa-vagrant-restore.log"
RHCSA_PROFILE="${RHCSA_PROFILE:-rhel9}"

log() {
  local msg="$1"
  printf '%s %s\n' "$(date '+%F %T')" "$msg" >> "$LOG_FILE"
  logger -t rhcsa-vagrant-restore "$msg" 2>/dev/null || true
}

generate_password() {
  tr -d '-' </proc/sys/kernel/random/uuid | cut -c 1-24
  printf '\n'
}

ensure_log() {
  : > "$LOG_FILE"
  chmod 600 "$LOG_FILE"
}

cleanup_legacy_unit() {
  systemctl unmask rhcsa-auto-restore-vagrant.service >/dev/null 2>&1 || true
  systemctl disable rhcsa-auto-restore-vagrant.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/rhcsa-auto-restore-vagrant.service \
        /usr/local/sbin/auto-restore-vagrant-access.sh \
        /usr/local/sbin/rhcsa-auto-restore-vagrant-access.sh \
        /etc/systemd/system/multi-user.target.wants/rhcsa-auto-restore-vagrant.service \
        /etc/systemd/system/multi-user.target.wants/rhcsa-auto-restore-vagrant.service.* 2>/dev/null || true
  systemctl daemon-reload >/dev/null 2>&1 || true
}

ensure_backup_keys() {
  install -d -m 700 "$BACKUP_DIR"

  if [[ -s "$VAGRANT_KEYS_BACKUP" ]]; then
    return 0
  fi

  if [[ -s /home/vagrant/.ssh/authorized_keys ]]; then
    cp -f /home/vagrant/.ssh/authorized_keys "$VAGRANT_KEYS_BACKUP"
    chmod 600 "$VAGRANT_KEYS_BACKUP"
    return 0
  fi

  echo "FATAL: cannot configure password recovery tooling without /home/vagrant/.ssh/authorized_keys." >&2
  exit 1
}

install_restore_scripts() {
  cat > "$RESTORE_CORE" <<'INNER_EOF'
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/root/.lab-backup"
BACKUP_KEYS="${BACKUP_DIR}/vagrant.authorized_keys"
PENDING_MARKER="${BACKUP_DIR}/vagrant_restore_pending"
LOG_FILE="/var/log/rhcsa-vagrant-restore.log"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

log() {
  local msg="$1"
  printf '%s %s\n' "$(date '+%F %T')" "$msg" >> "$LOG_FILE"
  logger -t rhcsa-vagrant-restore "$msg" 2>/dev/null || true
}

root_is_locked() {
  local hash
  hash="$(getent shadow root | cut -d: -f2 || true)"
  [[ -z "$hash" ]] && return 1
  [[ "$hash" == \!* || "$hash" == \** ]]
}

restore_keys() {
  if [[ ! -s "$BACKUP_KEYS" ]]; then
    log "restore: backup missing at $BACKUP_KEYS"
    return 0
  fi

  if ! id -u vagrant >/dev/null 2>&1; then
    log "restore: user vagrant not present"
    return 0
  fi

  install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
  install -m 600 -o vagrant -g vagrant "$BACKUP_KEYS" /home/vagrant/.ssh/authorized_keys
  restorecon -RF /home/vagrant/.ssh >/dev/null 2>&1 || true
  log "restore: repopulated /home/vagrant/.ssh/authorized_keys"
  return 0
}

main() {
  if [[ "$FORCE" -ne 1 ]]; then
    [[ -e "$PENDING_MARKER" ]] || exit 0
    if root_is_locked; then
      log "restore: root still locked; waiting for recovery to finish"
      exit 0
    fi
  fi

  restore_keys

  if [[ "$FORCE" -ne 1 ]]; then
    rm -f "$PENDING_MARKER" || true
    log "restore: cleared marker $PENDING_MARKER"
  fi
}

main || {
  log "restore: unexpected error; ignoring to avoid sshd start failure"
  exit 0
}
INNER_EOF
  chmod 700 "$RESTORE_CORE"

  cat > "$RESTORE_MANUAL" <<INNER_EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$RESTORE_CORE" --force
INNER_EOF
  chmod 700 "$RESTORE_MANUAL"
}

install_password_recovery_toggle() {
  cat > "$RECOVERY_TOGGLE" <<'INNER_EOF'
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/root/.lab-backup"
BACKUP_KEYS="${BACKUP_DIR}/vagrant.authorized_keys"
PENDING_MARKER="${BACKUP_DIR}/vagrant_restore_pending"
RESTORE_CORE="/usr/local/sbin/rhcsa-restore-vagrant-ssh.sh"
LOG_FILE="/var/log/rhcsa-vagrant-restore.log"

log() {
  local msg="$1"
  printf '%s %s\n' "$(date '+%F %T')" "$msg" >> "$LOG_FILE"
  logger -t rhcsa-vagrant-restore "$msg" 2>/dev/null || true
}

generate_password() {
tr -d '-' </proc/sys/kernel/random/uuid | cut -c 1-24
printf '\n'
}

enable_mode() {
  if [[ ! -s "$BACKUP_KEYS" ]]; then
    echo "Missing backup keys at $BACKUP_KEYS" >&2
    exit 1
  fi

  passwd -l root >/dev/null 2>&1 || true
  rm -f /home/vagrant/.ssh/authorized_keys /home/vagrant/.ssh/authorized_keys2 2>/dev/null || true

  : > "$PENDING_MARKER"
  chmod 600 "$PENDING_MARKER"

  gpasswd -d admin wheel >/dev/null 2>&1 || true

  printf 'vagrant:%s\n' "$(generate_password)" | chpasswd
  printf 'admin:%s\n' "$(generate_password)" | chpasswd

  log "password-recovery-mode: enabled"
}

disable_mode() {
  rm -f "$PENDING_MARKER" 2>/dev/null || true

  echo 'root:redhat' | chpasswd
  echo 'admin:redhat' | chpasswd

  if [[ -x "$RESTORE_CORE" ]]; then
    "$RESTORE_CORE" --force || true
  fi

  log "password-recovery-mode: disabled"
}

status_mode() {
  if [[ -e "$PENDING_MARKER" ]]; then
    echo "enabled"
  else
    echo "disabled"
  fi
}

case "${1:-}" in
  enable)
    enable_mode
    ;;
  disable)
    disable_mode
    ;;
  status)
    status_mode
    ;;
  *)
    echo "Usage: $0 {enable|disable|status}" >&2
    exit 1
    ;;
esac
INNER_EOF
  chmod 700 "$RECOVERY_TOGGLE"
}

install_sshd_dropin() {
  install -d -m 755 "$SSHD_DROPIN_DIR"
  cat > "$SSHD_DROPIN_FILE" <<INNER_EOF
[Service]
ExecStartPre=-$RESTORE_CORE
INNER_EOF
  systemctl daemon-reload
}

configure_local_repo() {
  cat > /etc/yum.repos.d/rhcsa-local.repo <<'EOF'
[rhcsa-baseos]
name=RHCSA Local BaseOS
baseurl=http://server/repo/BaseOS/
enabled=1
gpgcheck=0

[rhcsa-appstream]
name=RHCSA Local AppStream
baseurl=http://server/repo/AppStream/
enabled=1
gpgcheck=0
EOF
}

preload_container_assets() {
  [[ "$RHCSA_PROFILE" == "rhel9" ]] || return 0

  local asset_root="/opt/rhcsa/container-assets"
  local build_root="/var/tmp/rhcsa-httpd-rootfs"
  local rootfs_tar="${asset_root}/rhcsa-httpd-base-rootfs.tar"
  local image_archive="${asset_root}/rhcsa-httpd-base.tar"
  local image_name="localhost/rhcsa-httpd-base:latest"

  mkdir -p "$asset_root"
  rm -rf "$build_root"
  mkdir -p "$build_root"

  dnf -y \
    --installroot "$build_root" \
    --releasever=9 \
    --disablerepo='*' \
    --enablerepo=rhcsa-baseos \
    --enablerepo=rhcsa-appstream \
    --setopt=reposdir=/etc/yum.repos.d \
    --setopt=install_weak_deps=False \
    --setopt=tsflags=nodocs \
    install bash coreutils httpd >/dev/null

  dnf -y \
    --installroot "$build_root" \
    --releasever=9 \
    --disablerepo='*' \
    --enablerepo=rhcsa-baseos \
    --enablerepo=rhcsa-appstream \
    --setopt=reposdir=/etc/yum.repos.d \
    clean all >/dev/null || true

  rm -rf \
    "$build_root/var/cache/dnf" \
    "$build_root/var/log/dnf"* \
    "$build_root/var/log/yum."* \
    "$build_root/usr/share/doc" \
    "$build_root/usr/share/info" \
    "$build_root/usr/share/man"

  mkdir -p "$build_root/run/httpd" "$build_root/var/www/html"
  cat > "$build_root/var/www/html/index.html" <<'EOF'
RHCSA local container base image
EOF

  tar -C "$build_root" -cf "$rootfs_tar" .
  podman rmi -f "$image_name" >/dev/null 2>&1 || true
  podman import \
    --change 'CMD ["/usr/sbin/httpd","-DFOREGROUND"]' \
    --change 'EXPOSE 80' \
    --change 'STOPSIGNAL SIGWINCH' \
    "$rootfs_tar" \
    "$image_name" >/dev/null 2>&1
  rm -f "$image_archive"
  skopeo copy --insecure-policy "containers-storage:${image_name}" "docker-archive:${image_archive}:${image_name}" >/dev/null 2>&1
  tar -tf "$image_archive" | grep -qx 'manifest.json'

  rm -f "$rootfs_tar"
  rm -rf "$build_root"
}

seed_client_workspace() {
  mkdir -p /opt/rhcsa/workspaces/container /opt/rhcsa/workspaces/scripts /opt/rhcsa/workspaces/default-perms
  cat > /opt/rhcsa/workspaces/container/README.txt <<'EOF'
This workspace is reused by the RHCSA v9 container scenarios.
EOF
  restorecon -RF /opt/rhcsa >/dev/null 2>&1 || true
}

reset_to_baseline() {
  "$RECOVERY_TOGGLE" disable
}

main() {
  ensure_log
  cleanup_legacy_unit
  ensure_backup_keys
  install_restore_scripts
  install_password_recovery_toggle
  install_sshd_dropin
  configure_local_repo
  preload_container_assets
  seed_client_workspace
  reset_to_baseline
}

main
