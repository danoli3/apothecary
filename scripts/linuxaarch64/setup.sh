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



     cd $WORKDIR && wget "https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Bonus%20Raspberry%20Pi%20GCC%2064-Bit%20Toolchains/Raspberry%20Pi%20GCC%2064-Bit%20Cross-Compiler%20Toolchains/Bookworm/GCC%2014.2.0/cross-gcc-14.2.0-pi_64.tar.gz/download" -O cross-gcc-14.2.0-pi_64.tar.gz && tar xf cross-gcc-14.2.0-pi_64.tar.gz &&rm cross-gcc-14.2.0-pi_64.tar.gz &&mv cross-pi-gcc-14.2.0-64 raspbian
                    
      - name: Clone rpi_rootfs Repository
        run: |
          mkdir -p $SYSROOT
          cd $SYSROOT
          git clone https://github.com/danoli3/rpi_rootfs.git $SYSROOT

      - name: Build RootFS
        run: |
          cd $SYSROOT &&
          sudo chmod +x ./build_rootfs_arm64.sh
          ./build_rootfs_arm64.sh download
          ./build_rootfs_arm64.sh create