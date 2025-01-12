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

sudo apt-get install -y aptitude build-essential gawk gcc g++ gfortran git texinfo bison libncurses-dev cmake unzip pkg-config flex openssl pigz autoconf automake tar figlet xz-utils libtool dos2unix
sudo apt-get install -y libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev libxrandr-dev libxinerama-dev libx11-dev libxext-dev libxcursor-dev libxi-dev ccache
sudo aptitude install -y gperf

echo "calculate formulas"
$ROOT/scripts/calculate_formulas.sh

export ARCH=jetson
export TYPE=linux

echo "building"
$ROOT/scripts/build.sh
