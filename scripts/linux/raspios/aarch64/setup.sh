#!/usr/bin/env bash
# Host tools + Debian bookworm arm64 sysroot for Raspberry Pi 64-bit.
# Official compiler is host GCC 10 (aarch64-linux-gnu-gcc-10), not the Pi GCC 14 tarball.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../sysroot_utils.sh
source "$SCRIPT_DIR/../sysroot_utils.sh"

CROSS_OS="${CROSS_OS:-bookworm}"
CROSS_OS="${CROSS_OS,,}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"
SYSROOT="${SYSROOT:-/opt/rpi-arm64-sysroot}"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-/usr}"
RPI_QEMU_ARCH="${RPI_QEMU_ARCH:-aarch64}"

if [[ "$CROSS_OS" != "bookworm" ]]; then
    echo "Unsupported CROSS_OS '$CROSS_OS' (official Raspberry Pi sysroot is bookworm)." >&2
    exit 1
fi

if rpi_is_native && [[ "$(uname -m)" == "aarch64" ]]; then
    echo "Detected Raspberry Pi OS on aarch64. Using native root as SYSROOT."
    SYSROOT="/"
    NATIVE=true
else
    NATIVE=false
fi

export SYSROOT TOOLCHAIN_ROOT NATIVE RPI_QEMU_ARCH

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must run as root (sudo)." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
HOST_PACKAGES=(
    ca-certificates
    curl
    pkg-config
    build-essential
    cmake
    ninja-build
    autoconf
    automake
    libtool
    flex
    bison
    gawk
    python3
    xz-utils
    git
)
if [[ "$NATIVE" != "true" ]]; then
    HOST_PACKAGES+=(
        debootstrap
        debian-archive-keyring
        qemu-user-static
        binfmt-support
        gcc-10-aarch64-linux-gnu
        g++-10-aarch64-linux-gnu
        binutils-aarch64-linux-gnu
        python3-pip
        gnupg
    )
fi
apt-get update
apt-get install -y --no-install-recommends "${HOST_PACKAGES[@]}"

if [[ "$NATIVE" != "true" ]]; then
    update-binfmts --enable qemu-aarch64 >/dev/null 2>&1 || true
fi

if [[ "$NATIVE" == "true" ]]; then
    echo "Native setup complete. SYSROOT=/"
else
    echo "Building Raspberry Pi aarch64 sysroot at $SYSROOT ($CROSS_OS)"
    mkdir -p "$(dirname "$SYSROOT")"
    if [[ -d "$SYSROOT/debootstrap" && ! -f "$SYSROOT/usr/lib/aarch64-linux-gnu/libc.so.6" ]]; then
        echo "Incomplete debootstrap leftover in $SYSROOT; rebuilding."
        rm -rf "$SYSROOT"
    fi
    if [[ ! -f "$SYSROOT/usr/lib/aarch64-linux-gnu/libc.so.6" ]]; then
        rm -rf "$SYSROOT"
        mkdir -p "$SYSROOT"
        if [[ ! -e /usr/share/debootstrap/scripts/bookworm ]]; then
            echo "Host debootstrap has no bookworm script; aliasing a Debian script."
            mkdir -p /usr/share/debootstrap/scripts
            if [[ -e /usr/share/debootstrap/scripts/sid ]]; then
                ln -sf sid /usr/share/debootstrap/scripts/bookworm
            elif [[ -e /usr/share/debootstrap/scripts/stable ]]; then
                ln -sf stable /usr/share/debootstrap/scripts/bookworm
            else
                echo "No debootstrap sid/stable script to alias as bookworm." >&2
                exit 1
            fi
        fi
        # Ubuntu's debian-archive-keyring is older than Debian 12's signing key
        # (F8D2585B8783D481). Fetch the current Bookworm archive keys for debootstrap.
        BOOKWORM_KEYRING="/usr/share/keyrings/debian-archive-bookworm-merged.gpg"
        mkdir -p /usr/share/keyrings /tmp/debian-archive-keys
        : > /tmp/debian-archive-keys/bookworm.asc
        for key in archive-key-12.asc archive-key-12-security.asc; do
            curl -fsSL "https://ftp-master.debian.org/keys/${key}" >> /tmp/debian-archive-keys/bookworm.asc
        done
        gpg --batch --dearmor < /tmp/debian-archive-keys/bookworm.asc > "$BOOKWORM_KEYRING"
        debootstrap --arch=arm64 --variant=minbase --foreign \
            --keyring="$BOOKWORM_KEYRING" \
            "$CROSS_OS" "$SYSROOT" "$DEBIAN_MIRROR"
        mkdir -p "$SYSROOT/usr/bin"
        cp /usr/bin/qemu-aarch64-static "$SYSROOT/usr/bin/qemu-aarch64-static"
        chmod +x "$SYSROOT/usr/bin/qemu-aarch64-static"
        rpi_sysroot_mount "$SYSROOT"
        trap 'rpi_sysroot_umount "$SYSROOT"' EXIT
        rpi_sysroot_run "/debootstrap/debootstrap --second-stage"
        cat >"$SYSROOT/etc/apt/sources.list" <<EOF
deb ${DEBIAN_MIRROR} ${CROSS_OS} main contrib
deb ${DEBIAN_MIRROR} ${CROSS_OS}-updates main contrib
deb http://security.debian.org/debian-security ${CROSS_OS}-security main contrib
EOF
        rpi_sysroot_umount "$SYSROOT"
        trap - EXIT
    else
        echo "Reusing existing sysroot at $SYSROOT"
        mkdir -p "$SYSROOT/usr/bin"
        cp /usr/bin/qemu-aarch64-static "$SYSROOT/usr/bin/qemu-aarch64-static"
        chmod +x "$SYSROOT/usr/bin/qemu-aarch64-static"
    fi
fi

if [[ "$NATIVE" != "true" ]]; then
    if [[ ! -x /usr/bin/aarch64-linux-gnu-gcc-10 ]]; then
        echo "aarch64-linux-gnu-gcc-10 not found after install." >&2
        exit 1
    fi
    aarch64-linux-gnu-gcc-10 --version | head -1
    test "$(aarch64-linux-gnu-gcc-10 -dumpversion | cut -d. -f1)" = "10"
    if ! cmake --version 2>/dev/null | grep -qE 'cmake version 3\.(2[2-9]|[3-9]|[0-9]{2,})'; then
        python3 -m pip install --no-cache-dir 'cmake==3.31.6'
    fi
    cmake --version | head -1
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
    {
        echo "SYSROOT=$SYSROOT"
        echo "TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT"
        echo "TOOLCHAIN_PREFIX=aarch64-linux-gnu"
        echo "GCC=gcc10"
        echo "GCC_VERSION=10"
        echo "NATIVE=$NATIVE"
        echo "RPI_QEMU_ARCH=$RPI_QEMU_ARCH"
        echo "PKG_CONFIG_SYSROOT_DIR=$SYSROOT"
        echo "PKG_CONFIG_LIBDIR=$SYSROOT/usr/lib/aarch64-linux-gnu/pkgconfig:$SYSROOT/usr/share/pkgconfig"
        echo "PKG_CONFIG_PATH="
    } >>"$GITHUB_ENV"
    if [[ "$NATIVE" == "true" ]]; then
        echo "CC=gcc-10" >>"$GITHUB_ENV"
        echo "CXX=g++-10" >>"$GITHUB_ENV"
    else
        echo "CC=aarch64-linux-gnu-gcc-10" >>"$GITHUB_ENV"
        echo "CXX=aarch64-linux-gnu-g++-10" >>"$GITHUB_ENV"
    fi
fi

echo "=== raspios aarch64 setup complete ==="
echo "SYSROOT=$SYSROOT"
echo "TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT"
echo "NATIVE=$NATIVE"
cd "$SCRIPT_DIR"
