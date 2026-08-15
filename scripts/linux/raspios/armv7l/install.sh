#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RPI_SLICE=armv7l
export GCC_TRIPLE=arm-linux-gnueabihf
export QEMU_STATIC=qemu-arm-static
export NATIVE_UNAME=armv7l
export DEFAULT_SYSROOT=/opt/rpi-armv7l-sysroot
# shellcheck source=../install_common.sh
source "$SCRIPT_DIR/../install_common.sh"
