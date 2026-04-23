#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

ensure_httpd_base_archive() {
  local archive="/opt/rhcsa/container-assets/rhcsa-httpd-base.tar"
  local image_name="localhost/rhcsa-httpd-base:latest"
  local build_root="/var/tmp/rhcsa-httpd-rootfs-lab46"
  local rootfs_tar="/var/tmp/rhcsa-httpd-base-lab46.tar"

  if [[ -f "$archive" ]] && skopeo inspect --raw "docker-archive:${archive}" >/dev/null 2>&1; then
    return 0
  fi

  rm -f "$archive"

  if podman image exists "$image_name" >/dev/null 2>&1; then
    skopeo copy --insecure-policy "containers-storage:${image_name}" "docker-archive:${archive}:${image_name}" >/dev/null 2>&1 && return 0
  fi

  rm -rf "$build_root"
  mkdir -p "$build_root" /opt/rhcsa/container-assets

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
  podman import \
    --change 'CMD ["/usr/sbin/httpd","-DFOREGROUND"]' \
    --change 'EXPOSE 80' \
    --change 'STOPSIGNAL SIGWINCH' \
    "$rootfs_tar" \
    "$image_name" >/dev/null 2>&1
  skopeo copy --insecure-policy "containers-storage:${image_name}" "docker-archive:${archive}:${image_name}" >/dev/null 2>&1
  tar -tf "$archive" | grep -qx 'manifest.json'

  rm -f "$rootfs_tar"
  rm -rf "$build_root"
}

ensure_httpd_base_archive || {
  echo "Failed to prepare /opt/rhcsa/container-assets/rhcsa-httpd-base.tar." >&2
  echo "Rebuild the baseline with .\\RHCSA.ps1 destroy and .\\RHCSA.ps1 up." >&2
  exit 1
}
userdel -r scope46 >/dev/null 2>&1 || true
