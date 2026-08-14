#!/usr/bin/env bash
# Install Raspberry Pi aarch64 *target* headers/libs into the sysroot.
# Never chroot to an interactive shell.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../sysroot_utils.sh
source "$SCRIPT_DIR/../sysroot_utils.sh"

SYSROOT="${SYSROOT:-/opt/rpi-arm64-sysroot}"
RPI_QEMU_ARCH="${RPI_QEMU_ARCH:-aarch64}"
export SYSROOT RPI_QEMU_ARCH

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must run as root (sudo)." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

TARGET_PACKAGES=(
    aptitude
    pkg-config
    ca-certificates
    libc6-dev
    linux-libc-dev
    libstdc++-12-dev
    libgcc-12-dev
    libgl1-mesa-dev
    libglu1-mesa-dev
    libegl1-mesa-dev
    libgles2-mesa-dev
    libx11-dev
    libxext-dev
    libxrandr-dev
    libxinerama-dev
    libxcursor-dev
    libxi-dev
    libxkbcommon-dev
    libwayland-dev
    wayland-protocols
    libasound2-dev
    libpulse-dev
    libudev-dev
    libdrm-dev
    zlib1g-dev
    ccache
)

if rpi_is_native && [[ "$(uname -m)" == "aarch64" ]]; then
    echo "Native Raspberry Pi: installing target packages on the host."
    apt-get update
    apt-get install -y --no-install-recommends "${TARGET_PACKAGES[@]}"
else
    if [[ ! -f "$SYSROOT/usr/lib/aarch64-linux-gnu/libc.so.6" ]]; then
        echo "Sysroot $SYSROOT is missing libc. Run setup.sh first." >&2
        exit 1
    fi
    mkdir -p "$SYSROOT/usr/bin"
    cp /usr/bin/qemu-aarch64-static "$SYSROOT/usr/bin/qemu-aarch64-static"
    chmod +x "$SYSROOT/usr/bin/qemu-aarch64-static"
    rpi_sysroot_mount "$SYSROOT"
    trap 'rpi_sysroot_umount "$SYSROOT"' EXIT
    rpi_sysroot_run "apt-get update"
    rpi_sysroot_run "apt-get install -y --no-install-recommends ${TARGET_PACKAGES[*]}"
    rpi_sysroot_umount "$SYSROOT"
    trap - EXIT
fi

echo "=== pkg-config (sysroot) ==="
export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/aarch64-linux-gnu/pkgconfig:$SYSROOT/usr/share/pkgconfig"
export PKG_CONFIG_PATH=""
pkg-config --list-all | head -20 || true

echo "=== raspios aarch64 install complete ==="
cd "$SCRIPT_DIR"
