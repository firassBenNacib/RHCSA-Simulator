#!/bin/bash
set -euo pipefail

BOOTSTRAP_REPO_FILE="/etc/yum.repos.d/rhcsa-bootstrap.repo"
BOOTSTRAP_ISO_MOUNT="/mnt/rhcsa-bootstrap-iso"
DNF_ARGS=()

get_node_name() {
  hostnamectl --static 2>/dev/null || hostname -s
}

configure_hosts() {
  grep -q '192.168.122.3 servervm' /etc/hosts || cat >> /etc/hosts <<'EOF'
192.168.122.3 servervm
192.168.122.2 clientvm
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

  if [[ "$node_name" == "servervm" && -d /var/www/html/repo/BaseOS && -d /var/www/html/repo/AppStream ]]; then
    write_bootstrap_repo_file "file:///var/www/html/repo/BaseOS" "file:///var/www/html/repo/AppStream"
    DNF_ARGS=(--disablerepo=* --enablerepo=rhcsa-bootstrap-baseos --enablerepo=rhcsa-bootstrap-appstream)
    return 0
  fi

  for _ in $(seq 1 60); do
    write_bootstrap_repo_file "http://servervm/repo/BaseOS/" "http://servervm/repo/AppStream/"
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
}

configure_hosts
if ! configure_bootstrap_repo; then
  node_name="$(get_node_name)"
  if [[ "$node_name" == "servervm" ]]; then
    echo "Failed to prepare the bootstrap repo from the attached ISO on servervm." >&2
  else
    echo "Failed to reach the offline HTTP repo from clientvm. Verify that servervm finished provisioning and is serving http://servervm/repo/." >&2
  fi
  exit 1
fi

dnf "${DNF_ARGS[@]}" makecache
dnf "${DNF_ARGS[@]}" install -y \
  openssh-server \
  openssh-clients \
  sudo \
  firewalld \
  policycoreutils-python-utils \
  chrony \
  cronie \
  at \
  tuned \
  vim-enhanced \
  bash-completion \
  rsync \
  curl \
  wget \
  tar \
  gzip \
  bzip2 \
  xz \
  acl \
  attr \
  autofs \
  nfs-utils \
  httpd \
  httpd-tools \
  lvm2 \
  xfsprogs \
  e2fsprogs \
  dosfstools \
  podman \
  skopeo \
  buildah

cleanup_bootstrap_repo

systemctl enable --now sshd firewalld crond atd tuned

if ! id admin >/dev/null 2>&1; then
  useradd -m admin
fi

echo 'admin:redhat' | chpasswd
echo 'root:redhat' | chpasswd
echo 'vagrant:redhat' | chpasswd

usermod -aG wheel admin || true

sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q '^PasswordAuthentication yes$' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

if grep -q '^#\?PermitRootLogin' /etc/ssh/sshd_config; then
  sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
else
  echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
fi

systemctl restart sshd

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

rhcsa_reset_lab_ipv4_profile() {
  local connection_name="${1:-}"
  local address="${2:-192.168.122.2/24}"
  local gateway="${3:-192.168.122.1}"
  local dns_server="${4:-192.168.122.3}"

  if [[ -z "${connection_name:-}" ]]; then
    connection_name="$(rhcsa_get_lab_connection_name || true)"
  fi

  [[ -n "${connection_name:-}" ]] || return 0

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

  nmcli connection modify "$connection_name" \
    ipv6.method ignore \
    ipv6.addresses "" \
    ipv6.gateway "" \
    ipv6.dns "" \
    connection.autoconnect yes >/dev/null 2>&1 || true
}

rhcsa_ensure_packages() {
  dnf install -y "$@"
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
printf 'rhcsa-v9-baseline-ready\n' > /etc/rhcsa/baseline-ready
