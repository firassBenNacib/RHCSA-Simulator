#!/bin/bash
set -euo pipefail

BOOTSTRAP_REPO_FILE="/etc/yum.repos.d/rhcsa-bootstrap.repo"
BOOTSTRAP_ISO_MOUNT="/mnt/rhcsa-bootstrap-iso"
RHCSA_PROFILE="${RHCSA_PROFILE:-rhel9}"
DNF_ARGS=()
DNF_INSTALL_ARGS=(--setopt=keepcache=0 --setopt=install_weak_deps=False)
if [[ "$RHCSA_PROFILE" == "rhel10" ]]; then
  # Treat the attached RHEL 10 DVD as authoritative during bootstrap. Compatible
  # base boxes can include older SELinux companion packages that must be replaced
  # before RHEL 10.2+ packages such as nfs-utils can be installed.
  DNF_INSTALL_ARGS+=(--nobest --allowerasing --setopt=protected_packages=)
fi
BASE_PACKAGES=(
  openssh-server
  openssh-clients
  sudo
  firewalld
  policycoreutils-python-utils
  chrony
  cronie
  rsyslog
  at
  tuned
  vim-enhanced
  bash-completion
  rsync
  curl
  wget
  tar
  gzip
  bzip2
  xz
  acl
  attr
  autofs
  nfs-utils
  httpd
  httpd-tools
  lvm2
  xfsprogs
  e2fsprogs
  dosfstools
)

get_node_name() {
  hostnamectl --static 2>/dev/null || hostname -s
}

NODE_NAME="${RHCSA_NODE_NAME:-$(get_node_name)}"
hostnamectl set-hostname "$NODE_NAME" >/dev/null 2>&1 || true

run_quiet() {
  local log_file
  local rc

  log_file="$(mktemp /tmp/rhcsa-quiet.XXXXXX.log)"
  if "$@" >"$log_file" 2>&1; then
    rm -f "$log_file"
    return 0
  fi

  rc=$?
  printf 'Command failed:' >&2
  printf ' %q' "$@" >&2
  printf '\n' >&2
  if [[ -s "$log_file" ]]; then
    tail -n "${RHCSA_ERROR_TAIL_LINES:-40}" "$log_file" >&2 || true
  fi
  rm -f "$log_file"
  return "$rc"
}

stop_background_package_managers() {
  systemctl stop packagekit.service packagekit dnf-makecache.service dnf-makecache.timer >/dev/null 2>&1 || true
  systemctl kill --kill-who=all packagekit.service dnf-makecache.service >/dev/null 2>&1 || true
}

wait_for_package_manager() {
  local deadline
  deadline=$((SECONDS + 90))

  while pgrep -x packagekitd >/dev/null 2>&1 || pgrep -x dnf >/dev/null 2>&1 || pgrep -x rpm >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
      echo "Timed out waiting for another package manager process to finish." >&2
      return 1
    fi
    sleep 2
  done
}

run_dnf_quiet() {
  stop_background_package_managers
  wait_for_package_manager
  run_quiet dnf "${DNF_ARGS[@]}" "$@"
}

missing_packages() {
  local package
  for package in "$@"; do
    rpm -q "$package" >/dev/null 2>&1 || printf '%s\n' "$package"
  done
}

install_missing_packages() {
  local packages=("$@")
  local missing=()
  mapfile -t missing < <(missing_packages "${packages[@]}")
  if [[ "${#missing[@]}" -eq 0 ]]; then
    return 0
  fi

  run_dnf_quiet "${DNF_INSTALL_ARGS[@]}" install -y "${missing[@]}"
}

if [[ "$RHCSA_PROFILE" == "rhel10" ]]; then
  if [[ "$NODE_NAME" == "client" ]]; then
    PROFILE_PACKAGES=(flatpak)
  else
    PROFILE_PACKAGES=()
  fi
else
  PROFILE_PACKAGES=(podman skopeo buildah)
fi

configure_hosts() {
  grep -q '192.168.122.3 server' /etc/hosts || cat >> /etc/hosts <<'EOF'
192.168.122.3 server
192.168.122.2 client
EOF
}

write_bootstrap_repo_file() {
  local baseos_url="$1"
  local appstream_url="$2"

  cat > "$BOOTSTRAP_REPO_FILE" <<EOF
[rhcsa-bootstrap-baseos]
name=RHCSA Bootstrap BaseOS
baseurl=${baseos_url}
enabled=1
gpgcheck=0

[rhcsa-bootstrap-appstream]
name=RHCSA Bootstrap AppStream
baseurl=${appstream_url}
enabled=1
gpgcheck=0
EOF
}

mount_bootstrap_iso() {
  local rom_dev="$1"

  mkdir -p "$BOOTSTRAP_ISO_MOUNT"
  if mountpoint -q "$BOOTSTRAP_ISO_MOUNT"; then
    return 0
  fi

  mount -t iso9660 -o ro "$rom_dev" "$BOOTSTRAP_ISO_MOUNT" >/dev/null 2>&1 && return 0
  mount -t udf -o ro "$rom_dev" "$BOOTSTRAP_ISO_MOUNT" >/dev/null 2>&1 && return 0
  return 1
}

configure_bootstrap_repo() {
  local node_name
  local rom_dev

  node_name="$(get_node_name)"

  rom_dev="$(lsblk -pnro NAME,TYPE | awk '$2=="rom"{print $1; exit}')"
  if [[ -n "${rom_dev:-}" ]]; then
    mount_bootstrap_iso "$rom_dev" || true
    if [[ -d "$BOOTSTRAP_ISO_MOUNT/BaseOS" && -d "$BOOTSTRAP_ISO_MOUNT/AppStream" ]]; then
      write_bootstrap_repo_file "file://${BOOTSTRAP_ISO_MOUNT}/BaseOS" "file://${BOOTSTRAP_ISO_MOUNT}/AppStream"
      DNF_ARGS=(--disablerepo=* --enablerepo=rhcsa-bootstrap-baseos --enablerepo=rhcsa-bootstrap-appstream)
      return 0
    fi
  fi

  if [[ "$node_name" == "server" && -d /var/www/html/repo/BaseOS && -d /var/www/html/repo/AppStream ]]; then
    write_bootstrap_repo_file "file:///var/www/html/repo/BaseOS" "file:///var/www/html/repo/AppStream"
    DNF_ARGS=(--disablerepo=* --enablerepo=rhcsa-bootstrap-baseos --enablerepo=rhcsa-bootstrap-appstream)
    return 0
  fi

  for _ in $(seq 1 60); do
    write_bootstrap_repo_file "http://server/repo/BaseOS/" "http://server/repo/AppStream/"
    DNF_ARGS=(--disablerepo=* --enablerepo=rhcsa-bootstrap-baseos --enablerepo=rhcsa-bootstrap-appstream)
    if dnf "${DNF_ARGS[@]}" -q makecache >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  DNF_ARGS=()
  return 1
}

cleanup_bootstrap_repo() {
  rm -f "$BOOTSTRAP_REPO_FILE"
  if mountpoint -q "$BOOTSTRAP_ISO_MOUNT"; then
    umount "$BOOTSTRAP_ISO_MOUNT" >/dev/null 2>&1 || true
  fi
}

authorize_vagrant_ssh_keys() {
  id vagrant >/dev/null 2>&1 || return 0

  install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
  touch /home/vagrant/.ssh/authorized_keys
  chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
  chmod 600 /home/vagrant/.ssh/authorized_keys

  local key
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    grep -qxF "$key" /home/vagrant/.ssh/authorized_keys || echo "$key" >> /home/vagrant/.ssh/authorized_keys
  done <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1YdxBpNlzxDqfJyw/QKow1F+wvG9hXGoqiysfJOn5Y spox@vagrant-dev
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zRdK8jlqm8tehUc9c9WhQ==
EOF

  install -d -m 700 /root/.ssh
  touch /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    grep -qxF "$key" /root/.ssh/authorized_keys || echo "$key" >> /root/.ssh/authorized_keys
  done <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1YdxBpNlzxDqfJyw/QKow1F+wvG9hXGoqiysfJOn5Y spox@vagrant-dev
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zRdK8jlqm8tehUc9c9WhQ==
EOF

}

configure_selinux_boot_policy() {
  [[ "$RHCSA_PROFILE" == "rhel10" ]] || return 0

  if [[ -f /etc/selinux/config ]]; then
    # RHCSA10 boxes that ship with SELinux disabled must relabel once before
    # enforcing mode is safe. The host workflow flips to enforcing after reboot.
    sed -ri 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
    grep -q '^SELINUXTYPE=' /etc/selinux/config || echo 'SELINUXTYPE=targeted' >> /etc/selinux/config
  fi

  if command -v grubby >/dev/null 2>&1; then
    grubby --update-kernel=ALL --remove-args="selinux=0 enforcing=0 enforcing=1" >/dev/null 2>&1 || true
    grubby --update-kernel=ALL --args="selinux=1 enforcing=0" >/dev/null 2>&1 || true
  fi
}

prepare_flatpak_repo() {
  [[ "$RHCSA_PROFILE" == "rhel10" ]] || return 0
  [[ "$NODE_NAME" == "client" ]] || return 0
  command -v flatpak >/dev/null 2>&1 || return 0

  local repo="/opt/rhcsa/flatpak/repo"
  local work="/opt/rhcsa/flatpak/build"
  rm -rf "$work"
  install -d -m 755 "$repo" "$work/runtime/files" "$work/runtime/usr" "$work/app/files/bin"

  cat > "$work/runtime/metadata" <<'EOF'
[Runtime]
name=org.rhcsa.Platform
runtime=org.rhcsa.Platform/x86_64/stable
sdk=org.rhcsa.Platform/x86_64/stable
EOF

  cat > "$work/app/metadata" <<'EOF'
[Application]
name=org.rhcsa.Tools
runtime=org.rhcsa.Platform/x86_64/stable
sdk=org.rhcsa.Platform/x86_64/stable
command=rhcsa-tools
EOF

  cat > "$work/app/files/bin/rhcsa-tools" <<'EOF'
#!/bin/sh
printf 'RHCSA10 tools\n'
EOF
  chmod +x "$work/app/files/bin/rhcsa-tools"
  flatpak build-finish --command=rhcsa-tools "$work/app" >/dev/null

  flatpak build-export --runtime --arch=x86_64 "$repo" "$work/runtime" stable >/dev/null
  flatpak build-export --arch=x86_64 "$repo" "$work/app" stable >/dev/null
  flatpak build-update-repo "$repo" >/dev/null
}

authorize_vagrant_ssh_keys
configure_hosts
if ! configure_bootstrap_repo; then
  node_name="$(get_node_name)"
  if [[ "$node_name" == "server" ]]; then
    echo "Failed to prepare the bootstrap repo from the attached ISO on server." >&2
  else
    echo "Failed to reach the offline HTTP repo from client. Verify that server finished provisioning and is serving http://server/repo/." >&2
  fi
  exit 1
fi

run_dnf_quiet makecache
install_missing_packages "${BASE_PACKAGES[@]}" "${PROFILE_PACKAGES[@]}"
for optional_package in gdisk man-pages; do
  stop_background_package_managers
  wait_for_package_manager || true
  dnf "${DNF_ARGS[@]}" "${DNF_INSTALL_ARGS[@]}" install -y "$optional_package" >/dev/null 2>&1 || true
done

configure_selinux_boot_policy
prepare_flatpak_repo

cleanup_bootstrap_repo

systemctl enable --now sshd firewalld crond atd tuned

if ! id admin >/dev/null 2>&1; then
  useradd -m admin
fi

echo 'admin:redhat' | chpasswd
echo 'root:redhat' | chpasswd
echo 'vagrant:redhat' | chpasswd
authorize_vagrant_ssh_keys

usermod -aG wheel admin || true

sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q '^PasswordAuthentication yes$' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

if grep -q '^#\?PermitRootLogin' /etc/ssh/sshd_config; then
  sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
else
  echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
fi

systemctl restart sshd
firewall-cmd --add-service=ssh >/dev/null 2>&1 || true
firewall-cmd --permanent --add-service=ssh >/dev/null 2>&1 || true

install -d -m 755 /usr/local/lib
install -d -m 755 /opt/rhcsa/workspaces
install -d -m 755 /etc/rhcsa

cat > /usr/local/lib/rhcsa-scenario-helpers.sh <<'EOF'
#!/usr/bin/env bash

rhcsa_log() {
  local msg="$1"
  printf '[rhcsa-scenario] %s\n' "$msg"
  logger -t rhcsa-scenario "$msg" 2>/dev/null || true
}

rhcsa_ensure_group() {
  local name="$1"
  getent group "$name" >/dev/null 2>&1 || groupadd "$name"
}

rhcsa_ensure_user() {
  local name="$1"
  local password="${2:-redhat}"

  id "$name" >/dev/null 2>&1 || useradd -m "$name"
  printf '%s:%s\n' "$name" "$password" | chpasswd
}

rhcsa_reset_dir() {
  local path="$1"
  rm -rf "$path"
  mkdir -p "$path"
}

rhcsa_seed_files() {
  local dir="$1"
  shift

  mkdir -p "$dir"
  for file_name in "$@"; do
    : > "${dir}/${file_name}"
  done
}

rhcsa_append_unique_line() {
  local line="$1"
  local file_path="$2"

  grep -Fxq "$line" "$file_path" 2>/dev/null || echo "$line" >> "$file_path"
}

rhcsa_remove_matching_lines() {
  local pattern="$1"
  local file_path="$2"

  if [[ -f "$file_path" ]]; then
    sed -i "\#${pattern}#d" "$file_path"
  fi
}

rhcsa_get_lab_connection_name() {
  local connection_name
  local device_name

  while IFS=: read -r connection_name device_name; do
    [[ -z "${device_name:-}" || "${device_name}" == "lo" ]] && continue
    if ip -o -4 addr show dev "$device_name" 2>/dev/null | awk '{print $4}' | grep -q '^192\.168\.122\.'; then
      printf '%s\n' "$connection_name"
      return 0
    fi
  done < <(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null)

  while IFS=: read -r connection_name device_name; do
    [[ -z "${device_name:-}" || "${device_name}" == "lo" ]] && continue
    printf '%s\n' "$connection_name"
    return 0
  done < <(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null)

  return 1
}

rhcsa_prune_duplicate_connections() {
  local connection_name="$1"
  local active_uuid=""

  [[ -n "${connection_name:-}" ]] || return 0

  active_uuid="$(
    nmcli -t -f UUID,NAME connection show --active 2>/dev/null |
      awk -F: -v name="$connection_name" '$2 == name {print $1; exit}'
  )"

  while IFS=: read -r connection_uuid existing_name; do
    [[ "$existing_name" == "$connection_name" ]] || continue
    [[ -n "$active_uuid" && "$connection_uuid" == "$active_uuid" ]] && continue
    nmcli connection delete uuid "$connection_uuid" >/dev/null 2>&1 || true
  done < <(nmcli -t -f UUID,NAME connection show 2>/dev/null)
}

rhcsa_reset_lab_ipv4_profile() {
  local connection_name="${1:-}"
  local address="${2:-192.168.122.2/24}"
  local gateway="${3:-192.168.122.1}"
  local dns_server="${4:-192.168.122.3}"

  if [[ -z "${connection_name:-}" ]]; then
    connection_name="$(rhcsa_get_lab_connection_name || true)"
  fi

  [[ -n "${connection_name:-}" ]] || return 0

  rhcsa_prune_duplicate_connections "$connection_name"

  nmcli connection modify "$connection_name" \
    ipv4.addresses "$address" \
    ipv4.gateway "$gateway" \
    ipv4.dns "$dns_server" \
    ipv4.method manual \
    connection.autoconnect yes >/dev/null 2>&1 || true
}

rhcsa_reset_lab_ipv6_profile() {
  local connection_name="${1:-}"

  if [[ -z "${connection_name:-}" ]]; then
    connection_name="$(rhcsa_get_lab_connection_name || true)"
  fi

  [[ -n "${connection_name:-}" ]] || return 0

  rhcsa_prune_duplicate_connections "$connection_name"

  nmcli connection modify "$connection_name" \
    ipv6.method ignore \
    ipv6.addresses "" \
    ipv6.gateway "" \
    ipv6.dns "" \
    connection.autoconnect yes >/dev/null 2>&1 || true
}

rhcsa_ensure_packages() {
  dnf -q install -y "$@" >/dev/null 2>&1 || dnf install -y "$@"
}

rhcsa_enable_services() {
  systemctl enable --now "$@"
}

rhcsa_disable_services() {
  systemctl disable --now "$@" >/dev/null 2>&1 || true
}

rhcsa_write_file() {
  local target="$1"
  install -D -m 0644 /dev/null "$target"
  cat > "$target"
}

rhcsa_reset_repo_directory() {
  local backup_dir="$1"
  local keep_file="${2:-}"

  mkdir -p "$backup_dir"
  find /etc/yum.repos.d -maxdepth 1 -type f | while read -r repo_file; do
    local repo_name
    repo_name="$(basename "$repo_file")"
    if [[ -n "$keep_file" && "$repo_name" == "$keep_file" ]]; then
      continue
    fi
    mv -f "$repo_file" "$backup_dir/$repo_name"
  done
}

rhcsa_remove_packages() {
  dnf remove -y "$@" >/dev/null 2>&1 || true
}

rhcsa_prepare_workspace() {
  local target="$1"
  mkdir -p "$target"
  restorecon -RF "$target" >/dev/null 2>&1 || true
}

rhcsa_validate_container_archive() {
  local archive_path="${1:-}"

  [[ -n "${archive_path:-}" && -f "$archive_path" ]] || return 1
  tar -tf "$archive_path" 2>/dev/null | grep -Eq '^(manifest.json|index.json)$'
}

rhcsa_rebuild_httpd_base_archive() {
  local archive_path="/opt/rhcsa/container-assets/rhcsa-httpd-base.tar"
  local image_name="localhost/rhcsa-httpd-base:latest"
  local build_root="/var/tmp/rhcsa-httpd-rootfs-rebuild"
  local rootfs_tar="/var/tmp/rhcsa-httpd-base-rebuild.tar"

  mkdir -p /opt/rhcsa/container-assets

  if podman image exists "$image_name" >/dev/null 2>&1; then
    rm -f "$archive_path"
    if skopeo copy --insecure-policy "containers-storage:${image_name}" "docker-archive:${archive_path}:${image_name}" >/dev/null 2>&1 &&
      rhcsa_validate_container_archive "$archive_path"; then
      return 0
    fi
  fi

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
  echo 'RHCSA local container base image' > "$build_root/var/www/html/index.html"

  tar -C "$build_root" -cf "$rootfs_tar" .
  podman rmi -f "$image_name" >/dev/null 2>&1 || true
  podman import \
    --change 'CMD ["/usr/sbin/httpd","-DFOREGROUND"]' \
    --change 'EXPOSE 80' \
    --change 'STOPSIGNAL SIGWINCH' \
    "$rootfs_tar" \
    "$image_name" >/dev/null 2>&1

  rm -f "$archive_path"
  skopeo copy --insecure-policy "containers-storage:${image_name}" "docker-archive:${archive_path}:${image_name}" >/dev/null 2>&1 || return 1
  rhcsa_validate_container_archive "$archive_path"
  local status=$?
  rm -f "$rootfs_tar"
  rm -rf "$build_root"
  return $status
}

rhcsa_ensure_httpd_base_archive() {
  local archive_path="/opt/rhcsa/container-assets/rhcsa-httpd-base.tar"

  if rhcsa_validate_container_archive "$archive_path"; then
    return 0
  fi

  rhcsa_log "rebuilding ${archive_path}"
  rhcsa_rebuild_httpd_base_archive
}

rhcsa_configure_password_recovery() {
  local mode="$1"

  if [[ ! -x /usr/local/sbin/rhcsa-password-recovery-mode ]]; then
    echo "Password recovery helper is not installed on this VM." >&2
    return 1
  fi

  /usr/local/sbin/rhcsa-password-recovery-mode "$mode"
}
EOF

chmod 755 /usr/local/lib/rhcsa-scenario-helpers.sh
printf 'rhcsa-%s-baseline-ready\n' "$RHCSA_PROFILE" > /etc/rhcsa/baseline-ready
