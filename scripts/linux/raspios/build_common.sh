#!/usr/bin/env bash
# Shared Raspberry Pi formula build. Required: RPI_SLICE GCC_TRIPLE DEFAULT_SYSROOT NATIVE_UNAME
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=sysroot_utils.sh
source "$SCRIPT_DIR/sysroot_utils.sh"

: "${RPI_SLICE:?}"
: "${GCC_TRIPLE:?}"
: "${DEFAULT_SYSROOT:?}"
: "${NATIVE_UNAME:?}"

if rpi_is_native && [[ "$(uname -m)" == "$NATIVE_UNAME" ]]; then
    export SYSROOT="${SYSROOT:-/}"
    export TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-/usr}"
    if command -v gcc-10 >/dev/null 2>&1; then
        export CC="${CC:-gcc-10}"
        export CXX="${CXX:-g++-10}"
    else
        export CC="${CC:-gcc}"
        export CXX="${CXX:-g++}"
    fi
else
    export SYSROOT="${SYSROOT:-$DEFAULT_SYSROOT}"
    export TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-/usr}"
    export CC="${CC:-${GCC_TRIPLE}-gcc-10}"
    export CXX="${CXX:-${GCC_TRIPLE}-g++-10}"
fi

export TARGET="${TARGET:-linux}"
export TYPE="${TYPE:-linux}"
export ARCH="${ARCH:-$RPI_SLICE}"
export GCC="${GCC:-gcc10}"
export GCC_VERSION="${GCC_VERSION:-10}"
export TOOLCHAIN_PREFIX="${TOOLCHAIN_PREFIX:-$GCC_TRIPLE}"
export RPI_QEMU_ARCH="${RPI_QEMU_ARCH:-$RPI_SLICE}"
export PKG_CONFIG_SYSROOT_DIR="${PKG_CONFIG_SYSROOT_DIR:-$SYSROOT}"
export PKG_CONFIG_LIBDIR="${PKG_CONFIG_LIBDIR:-$SYSROOT/usr/lib/${GCC_TRIPLE}/pkgconfig:$SYSROOT/usr/share/pkgconfig}"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

if [[ -z "${LINUX_ARTIFACT_TARGET:-}" ]]; then
    # shellcheck source=../map_artifact_target.sh
    source "$REPO_ROOT/scripts/linux/map_artifact_target.sh"
    LINUX_ARTIFACT_TARGET="$(map_linux_artifact_target "$ARCH")"
    export LINUX_ARTIFACT_TARGET
fi

echo "TARGET=$TARGET ARCH=$ARCH GCC=$GCC"
echo "SYSROOT=$SYSROOT TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT"
echo "CC=$CC CXX=$CXX"
echo "LINUX_ARTIFACT_TARGET=$LINUX_ARTIFACT_TARGET"

cd "$REPO_ROOT"
"$REPO_ROOT/scripts/calculate_formulas.sh"
"$REPO_ROOT/scripts/build.sh"

echo "=== raspios $RPI_SLICE build complete ==="
