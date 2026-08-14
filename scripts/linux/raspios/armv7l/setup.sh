#!/usr/bin/env bash
# Host tools + Debian bookworm armhf sysroot for Raspberry Pi 32-bit v7.
# Official compiler is host GCC 10 (arm-linux-gnueabihf-gcc-10), hard-float.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RPI_SLICE=armv7l
export DEB_ARCH=armhf
export GCC_TRIPLE=arm-linux-gnueabihf
export QEMU_STATIC=qemu-arm-static
export QEMU_BINFMT=qemu-arm
export NATIVE_UNAME=armv7l
export DEFAULT_SYSROOT=/opt/rpi-armv7l-sysroot
# shellcheck source=../setup_common.sh
source "$SCRIPT_DIR/../setup_common.sh"
