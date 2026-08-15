#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RPI_SLICE=aarch64
export GCC_TRIPLE=aarch64-linux-gnu
export QEMU_STATIC=qemu-aarch64-static
export NATIVE_UNAME=aarch64
export DEFAULT_SYSROOT=/opt/rpi-arm64-sysroot
# shellcheck source=../install_common.sh
source "$SCRIPT_DIR/../install_common.sh"
