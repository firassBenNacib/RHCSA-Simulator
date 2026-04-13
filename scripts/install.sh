#!/usr/bin/env bash
set -euo pipefail

REPO="bennacib/rhcsa_exam_vms"
BINARY="rhcsa-tui"
OWNER="${OWNER:-bennacib}"

get_os() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        linux*) echo "linux" ;;
        darwin*) echo "darwin" ;;
        cygwin*|mingw*|msys) echo "windows" ;;
        *) echo " unsupported OS: $os" >&2; exit 1 ;;
    esac
}

get_arch() {
    arch=$(uname -m | tr '[:upper:]' '[:lower:]')
    case "$arch" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        arm*) echo "arm64" ;;
        *) echo " unsupported architecture: $arch" >&2; exit 1 ;;
    esac
}

get_extension() {
    if [ "$(get_os)" = "windows" ]; then
        echo "zip"
    else
        echo "tar.gz"
    fi
}

install() {
    local version="${1:-latest}"
    local os=$(get_os)
    local arch=$(get_arch)
    local ext=$(get_extension)
    local prefix="${OWNER}"
    local repo="${prefix}/rhcsa_exam_vms"

    if [ "$version" = "latest" ]; then
        local url="https://github.com/${repo}/releases/latest/download"
    else
        local url="https://github.com/${repo}/releases/download/${version}"
    fi

    local filename="${BINARY}_${os}_${arch}.${ext}"
    local download_url="${url}/${filename}"
    local checksum_url="${url}/checksums.txt"

    echo "Installing ${BINARY} ${version} for ${os}/${arch}..."

    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    echo "Downloading ${download_url}..."
    if command -v curl &> /dev/null; then
        curl -fsSL "$download_url" -o "${temp_dir}/${filename}"
        curl -fsSL "$checksum_url" -o "${temp_dir}/checksums.txt"
    elif command -v wget &> /dev/null; then
        wget -q "$download_url" -O "${temp_dir}/${filename}"
        wget -q "$checksum_url" -O "${temp_dir}/checksums.txt"
    else
        echo "Error: curl or wget is required" >&2
        exit 1
    fi

    cd "$temp_dir"
    if [ "$ext" = "zip" ]; then
        unzip -o "$filename"
    else
        tar -xzf "$filename"
    fi

    local bin_dir="$HOME/.local/bin"
    if [ -d "$HOME/.local/bin" ]; then
        :
    elif [ -d "$HOME/bin" ]; then
        bin_dir="$HOME/bin"
    else
        mkdir -p "$bin_dir"
    fi

    mv "${temp_dir}/${BINARY}" "${bin_dir}/${BINARY}"
    chmod +x "${bin_dir}/${BINARY}"

    echo ""
    echo "Installed to ${bin_dir}/${BINARY}"
    echo ""

    if [[ ":$PATH:" != *":${bin_dir}:"* ]]; then
        echo "Add to PATH:"
        echo "  export PATH=\"\${HOME}/.local/bin:\$PATH\""
    fi
}

version="${1:-}"
if [[ "$version" == --* ]]; then
    case "$1" in
        --version|-v) install "latest" ;;
        --help|-h)
            echo "Usage: install.sh [version]"
            echo ""
            echo "Options:"
            echo "  -v, --version    Install latest version"
            echo "  [version]        Install specific version (e.g., v1.0.0)"
            echo ""
            echo "Environment:"
            echo "  OWNER            GitHub repo owner (default: bennacib)"
            exit 0
            ;;
    esac
fi

install "$version"
