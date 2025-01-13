#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR
APOTHECARY_LEVEL="$( cd "$SCRIPT_DIR/../.." && pwd )"
cd $APOTHECARY_LEVEL

CROSS_COMPILER=""
CROSS_SYSROOT=""
CROSS_ARCH="aarch64"

if [ "${CROSSCOMPILE}" -eq 0 ]; then
    export ROOTFS="/"
    export TOOLCHAIN_ROOT="/${CROSS_COMPILER}"
else
    export ROOTFS="${APOTHECARY_LEVEL}/${CROSS_SYSROOT}"
    export TOOLCHAIN_ROOT="${APOTHECARY_LEVEL}/${CROSS_COMPILER}"
fi
export HOST_ARCH=$(uname -m)
export HOST_PLATFORM=$(uname)
export SYSROOT=${ROOTFS}
export GCC_PREFIX="${CROSS_ARCH}-linux-gnu"
if [ "${GCC_VERSION}" -eq 0 ]; then
    export GCC_VERSION="14.2.0"
fi

export CMAKE_LIBRARY_ARCHITECTURE=${GCC_PREFIX}
export LIBRARY_PATH=${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/lib64:${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/lib:${TOOLCHAIN_ROOT}/lib
export LD_LIBRARY_PATH=${TOOLCHAIN_ROOT}/lib
export PATH=$TOOLCHAIN_ROOT/bin:$LIBRARY_PATH:$PATH
