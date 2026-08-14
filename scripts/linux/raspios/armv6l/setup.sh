#!/usr/bin/env bash
# Host tools + Debian bookworm armhf sysroot for Raspberry Pi 1 / Zero (armv6).
# Official compiler is host GCC 10 (arm-linux-gnueabihf-gcc-10) with v6 flags.
# Not Debian armel — Raspberry Pi OS is hard-float.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RPI_SLICE=armv6l
export DEB_ARCH=armhf
export GCC_TRIPLE=arm-linux-gnueabihf
export QEMU_STATIC=qemu-arm-static
export QEMU_BINFMT=qemu-arm
export NATIVE_UNAME=armv6l
export DEFAULT_SYSROOT=/opt/rpi-armv6l-sysroot
# shellcheck source=../setup_common.sh
source "$SCRIPT_DIR/../setup_common.sh"
