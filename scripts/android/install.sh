#!/usr/bin/env bash
set -e
APOTHECARY_PATH=$(cd $(dirname "$0"); pwd -P)/../../apothecary

sudo apt-get install -y aptitude build-essential gawk gcc g++ gfortran git texinfo bison libncurses-dev cmake unzip pkg-config flex openssl pigz autoconf automake tar figlet xz-utils libtool dos2unix
sudo apt-get install -y libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev libxrandr-dev libxinerama-dev libx11-dev libxext-dev libxcursor-dev libxi-dev ccache
sudo aptitude install -y gperf

NDK_VERSION="r24"
export NDK_ROOT="$(realpath ~/)/android-ndk-${NDK_VERSION}/"

# Check if cached NDK directory exists
if [ "$(ls -A ${NDK_ROOT})" ]; then
    echo "Using cached NDK"
    ls -A ${NDK_ROOT}
else
    cd ~/
    echo "Downloading NDK $NDK_VERSION"
    wget -q --no-check-certificate https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip
    echo "Uncompressing NDK"
    unzip android-ndk-${NDK_VERSION}-linux.zip > /dev/null 2>&1
    rm android-ndk-${NDK_VERSION}-linux.zip
    echo "NDK installed at $NDK_ROOT"
    cd -
fi

echo "NDK_ROOT=${NDK_ROOT};" > ${APOTHECARY_PATH}/paths.make

