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

sudo apt-get install -y aptitude
sudo aptitude install -y gperf

ROOT=/home/runner/work/apothecary/apothecary
echo $ROOT
cd $ROOT
RASP="$ROOT/raspbianpi3ab45"

PATH=$RASP/bin:$PATH
LD_LIBRARY_PATH=$RASP/lib:$LD_LIBRARY_PATH

export GCC_PREFIX=arm-linux-gnueabihf
export GCC_VERSION="14.2.0" # UPDATE THIS AS NEEDED /libexec/gcc/arm-linux-gnueabihf/*/

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
