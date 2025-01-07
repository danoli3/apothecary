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

sudo apt-get install -y aptitude build-essential gawk gcc g++ gfortran git texinfo bison libncurses-dev cmake unzip pkg-config flex openssl pigz autoconf automake tar figlet
sudo aptitude install -y gperf
wget https://raw.githubusercontent.com/abhiTronix/raspberry-pi-cross-compilers/master/utils/SSymlinker

ROOT=/home/runner/work/apothecary/apothecary
echo $ROOT
cd $ROOT
export RASP="$ROOT/raspbianpi1zero"

PATH=$RASP/bin:$PATH

export GCC_PREFIX=arm-linux-gnueabihf
export GCC_VERSION="14.2.0" # UPDATE THIS AS NEEDED /libexec/gcc/arm-linux-gnueabihf/*/

LD_LIBRARY_PATH=${RASP}/${GCC_PREFIX}/libc/usr/lib:${RASP}/${GCC_PREFIX}/libc/lib:${RASP}/lib

export AR="${GCC_PREFIX}-gcc-ar"
export CC="${GCC_PREFIX}-gcc"
export CXX="${GCC_PREFIX}-g++"
export CPP="${GCC_PREFIX}-cpp"
export FC="${GCC_PREFIX}-gfortran"
export RANLIB="${GCC_PREFIX}-gcc-ranlib"
export LD="$CXX"

GCCPATH="$RASP/libexec/gcc/${GCC_PREFIX}/${GCC_VERSION}"
export ARFLAGS="--plugin $GCCPATH/liblto_plugin.so"
export RANLIBFLAGS="--plugin $GCCPATH/liblto_plugin.so"

export LIBC_USR=${RASP}/${GCC_PREFIX}/libc/usr/
export CRT=${LIBC_USR}/lib

sudo chmod +x SSymlinker
./SSymlinker -s ${LIBC_USR}/include/asm -d /usr/include
./SSymlinker -s ${LIBC_USR}/include/gnu -d /usr/include
./SSymlinker -s ${LIBC_USR}/include/bits -d /usr/include
./SSymlinker -s ${LIBC_USR}/include/sys -d /usr/include
./SSymlinker -s ${LIBC_USR}/include/sound -d /usr/include
./SSymlinker -s ${LIBC_USR}/include/video -d /usr/include
./SSymlinker -s ${LIBC_USR}/include -d /usr/include
./SSymlinker -s ${CRT}/crtn.o -d /usr/lib/crtn.o
./SSymlinker -s ${CRT}/crt1.o -d /usr/lib/crt1.o
./SSymlinker -s ${CRT}/crti.o -d /usr/lib/crti.o

echo 'export PATH=$PATH' >> .bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH' >> .bashrc
source .bashrc

#echo "ROOT dir "
#ls -la $ROOT
#
#echo "RASP dir "
#ls -la $RASP
#
#echo "GCCPATH IS "
#echo $GCCPATH

echo "calculate formulas"
$ROOT/scripts/calculate_formulas.sh

echo "building"
$ROOT/scripts/build.sh
