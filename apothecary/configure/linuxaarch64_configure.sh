#!/usr/bin/env bash
# Raspberry Pi OS 64-bit (ARCH=aarch64) compiler/sysroot.
# Official CI uses host GCC 10 + a bookworm arm64 sysroot.

ORIGINAL_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APOTHECARY_LEVEL="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../scripts/linux/raspios/sysroot_utils.sh
if [[ -f "$APOTHECARY_LEVEL/scripts/linux/raspios/sysroot_utils.sh" ]]; then
    source "$APOTHECARY_LEVEL/scripts/linux/raspios/sysroot_utils.sh"
fi

export HOST_ARCH
HOST_ARCH="$(uname -m)"
export HOST_PLATFORM
HOST_PLATFORM="$(uname)"
export GCC_PREFIX="${GCC_PREFIX:-aarch64-linux-gnu}"
export GCC_VERSION="${GCC_VERSION:-10}"

if type rpi_is_native >/dev/null 2>&1 && rpi_is_native && [[ "$HOST_ARCH" == "aarch64" ]]; then
    CROSSCOMPILE=0
else
    if [[ "$HOST_ARCH" == "aarch64" || "$HOST_ARCH" == "arm64" ]]; then
        CROSSCOMPILE=0
    else
        CROSSCOMPILE=1
    fi
fi
export CROSSCOMPILE
export CROSSCOMPILING="$CROSSCOMPILE"

if [[ "$CROSSCOMPILE" -eq 0 ]]; then
    export ROOTFS="${SYSROOT:-/}"
    export SYSROOT="${SYSROOT:-/}"
    export TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-/usr}"
    if command -v gcc-10 >/dev/null 2>&1; then
        export CC="${CC:-gcc-10}"
        export CXX="${CXX:-g++-10}"
    else
        export CC="${CC:-gcc}"
        export CXX="${CXX:-g++}"
    fi
    export AR="${AR:-ar}"
    export AS="${AS:-as}"
    export RANLIB="${RANLIB:-ranlib}"
    export LD="${LD:-ld}"
else
    export ROOTFS="${SYSROOT:-/opt/rpi-arm64-sysroot}"
    export SYSROOT="${SYSROOT:-/opt/rpi-arm64-sysroot}"
    export TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-/usr}"
    export CC="${CC:-${GCC_PREFIX}-gcc-10}"
    export CXX="${CXX:-${GCC_PREFIX}-g++-10}"
    export AR="${AR:-${GCC_PREFIX}-ar}"
    export AS="${AS:-${GCC_PREFIX}-as}"
    export RANLIB="${RANLIB:-${GCC_PREFIX}-ranlib}"
    export LD="${LD:-${GCC_PREFIX}-ld}"
fi

export CMAKE_LIBRARY_ARCHITECTURE="${GCC_PREFIX}"
export PKG_CONFIG_SYSROOT_DIR="${PKG_CONFIG_SYSROOT_DIR:-$SYSROOT}"
export PKG_CONFIG_LIBDIR="${PKG_CONFIG_LIBDIR:-$SYSROOT/usr/lib/${GCC_PREFIX}/pkgconfig:$SYSROOT/usr/share/pkgconfig}"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"
export HOST="${GCC_PREFIX}"

if [[ "$SYSROOT" == "/" ]]; then
    export CFLAGS="${CFLAGS:--fPIC -O2 -march=armv8-a -mtune=cortex-a53}"
    export CXXFLAGS="${CXXFLAGS:--fPIC -O2 -march=armv8-a -mtune=cortex-a53}"
    export LDFLAGS="${LDFLAGS:-}"
else
    export CFLAGS="${CFLAGS:---sysroot=${SYSROOT} -fPIC -O2 -march=armv8-a -mtune=cortex-a53}"
    export CXXFLAGS="${CXXFLAGS:---sysroot=${SYSROOT} -fPIC -O2 -march=armv8-a -mtune=cortex-a53}"
    export LDFLAGS="${LDFLAGS:---sysroot=${SYSROOT} -Wl,-rpath-link,${SYSROOT}/usr/lib/${GCC_PREFIX} -L${SYSROOT}/usr/lib/${GCC_PREFIX}}"
fi

echo "--------------------"
echo "openFrameworks apothecary Raspberry Pi aarch64"
echo "CROSSCOMPILE: $CROSSCOMPILE"
echo "GCC_PREFIX: $GCC_PREFIX"
echo "GCC_VERSION: $GCC_VERSION"
echo "CC: $CC"
echo "CXX: $CXX"
echo "SYSROOT: $SYSROOT"
echo "TOOLCHAIN_ROOT: $TOOLCHAIN_ROOT"
echo "HOST_ARCH: $HOST_ARCH"
echo "--------------------"
cd "$ORIGINAL_DIR"
