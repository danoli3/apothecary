#!/usr/bin/env bash
# Host tools + Debian bookworm arm64 sysroot for Raspberry Pi 64-bit.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RPI_SLICE=aarch64
export DEB_ARCH=arm64
export GCC_TRIPLE=aarch64-linux-gnu
export QEMU_STATIC=qemu-aarch64-static
export QEMU_BINFMT=qemu-aarch64
export NATIVE_UNAME=aarch64
export DEFAULT_SYSROOT=/opt/rpi-arm64-sysroot
# shellcheck source=../setup_common.sh
source "$SCRIPT_DIR/../setup_common.sh"
