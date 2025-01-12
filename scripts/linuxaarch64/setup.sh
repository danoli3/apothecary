#!/bin/bash
set -e
set -o pipefail
# trap any script errors and exit
trap "trapError" ERR

trapError() {
	echo
	echo " ^ Received error ^"
	cat formula.log
	exit 1
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR
APOTHECARY_LEVEL="$( cd "$SCRIPT_DIR/../.." && pwd )"
cd $APOTHECARY_LEVEL

CROSS_COMPILER=raspbian
CROSS_SYSROOT=rpi_rootfs
CROSS_URL="https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Bonus%20Raspberry%20Pi%20GCC%2064-Bit%20Toolchains/Raspberry%20Pi%20GCC%2064-Bit%20Cross-Compiler%20Toolchains/Bookworm/GCC%2014.2.0/cross-gcc-14.2.0-pi_64.tar.gz/download" 
CROSS_NAME=cross-gcc-14.2.0-pi_64
CROSS_EXTRACT=cross-pi-gcc-14.2.0-64

wget "${CROSS_URL}" -O ${CROSS_NAME}.tar.gz && tar xf ${CROSS_NAME}.tar.gz && rm ${CROSS_NAME}.tar.gz && mv ${CROSS_EXTRACT} ${CROSS_COMPILER}

git clone https://github.com/danoli3/rpi_rootfs.git
cd $CROSS_SYSROOT

sudo chmod +x ./build_rootfs_arm64.sh

./build_rootfs_arm64.sh download
./build_rootfs_arm64.sh create

echo "setup complete"