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
CROSS_URL="https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains/Bookworm/GCC%2014.2.0/Raspberry%20Pi%201%2C%20Zero/cross-gcc-14.2.0-pi_0-1.tar.gz/download" 
CROSS_NAME=cross-gcc-14.2.0-pi_0-1
CROSS_EXTRACT=cross-pi-gcc-14.2.0-0

wget "${CROSS_URL}" -O ${CROSS_NAME}.tar.gz && tar xf ${CROSS_NAME}.tar.gz && rm ${CROSS_NAME}.tar.gz && mv ${CROSS_EXTRACT} ${CROSS_COMPILER}


git clone https://github.com/danoli3/rpi_rootfs.git
cd $CROSS_SYSROOT

sudo chmod +x ./build_rootfs.sh
./build_rootfs.sh download
./build_rootfs.sh create

echo "setup complete"