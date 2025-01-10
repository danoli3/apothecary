#!/usr/bin/env bash
set -e

# trap any script errors and exit
trap "trapError" ERR

trapError() {
	echo
	echo " ^ Received error ^"
	exit 1
}

isRunning(){
    if [ “$(uname)” == “Linux” ]; then
		if [ -d /proc/$1 ]; then
	    	return 0
        else
            return 1
        fi
    else
        number=$(ps aux | sed -E "s/[^ ]* +([^ ]*).*/\1/g" | grep ^$1$ | wc -l)

        if [ $number -gt 0 ]; then
            return 0;
        else
            return 1;
        fi
    fi
}

echoDots(){
    while isRunning $1; do
        for i in $(seq 1 10); do
            echo -ne .
            if ! isRunning $1; then
                printf "\r"
                return;
            fi
            sleep 2
        done
        printf "\r                    "
        printf "\r"
    done
}

echo "GCC Version: [$GCC]"

if [ "$GCC" == "gcc4" ]; then
    sudo add-apt-repository -y ppa:dns/gnu
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt-get update -q
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo apt-get install -y --allow-unauthenticated gcc-4.9 g++-4.9
    #needed because github actions defaults to gcc 5
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 60
    sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 60
    sudo update-alternatives --set cc /usr/bin/gcc
    sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 60
    sudo update-alternatives --set c++ /usr/bin/g++
elif [ "$GCC" == "gcc5" ]; then
    sudo add-apt-repository -y ppa:dns/gnu
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt-get update -q
    sudo apt-get install -y --allow-unauthenticated gcc-5 g++-5
    sudo apt-get install -f
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo apt-get remove -y --purge g++-4.8
    sudo apt-get autoremove
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 100
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 100
    g++ -v
elif [ "$GCC" == "gcc6" ]; then
    
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
    sudo apt-get update
    sudo add-apt-repository -y "deb http://cz.archive.ubuntu.com/ubuntu bionic main universe"
    sudo apt-get update
    sudo apt-get install -y --allow-unauthenticated gcc-6 g++-6
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo apt-get autoremove
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-6 100
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 100
    sudo add-apt-repository -r "deb http://cz.archive.ubuntu.com/ubuntu bionic main universe"

    g++ -v
elif [ "$GCC" == "gcc7" ]; then
    #https://gcc.gnu.org/gcc-7/changes.html
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
    sudo apt-get update
    sudo add-apt-repository -y "deb http://cz.archive.ubuntu.com/ubuntu focal main universe"
    sudo apt-get update
    sudo apt-get install -y --allow-unauthenticated gcc-7 g++-7
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo apt-get autoremove
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
    sudo add-apt-repository -r "deb http://cz.archive.ubuntu.com/ubuntu bionic main universe"
    g++ -v
elif [ "$GCC" == "gcc8" ]; then
    #https://gcc.gnu.org/gcc-8/changes.html
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test
    sudo apt update
    sudo apt install -y --allow-unauthenticated gcc-8 g++-8
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8 --slave /usr/bin/g++ g++ /usr/bin/g++-8
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo update-alternatives --config gcc
    gcc --version
    g++ -v
elif [ "$GCC" == "gcc11" ]; then
    # https://gcc.gnu.org/gcc-11/changes.html
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test
    sudo apt update
    sudo apt install -y --allow-unauthenticated gcc-11 g++-11 -y
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 11 --slave /usr/bin/g++ g++ /usr/bin/g++-11
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo update-alternatives --config gcc
    gcc --version
    g++ -v
elif [ "$GCC" == "gcc12" ]; then
    # https://gcc.gnu.org/gcc-12/changes.html
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test
    sudo apt update
    sudo apt install -y --allow-unauthenticated gcc-12 g++-12
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 12 --slave /usr/bin/g++ g++ /usr/bin/g++-12
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo update-alternatives --config gcc
    gcc --version
    g++ -v
elif [ "$GCC" == "gcc13" ]; then
    # https://gcc.gnu.org/gcc-13/changes.html
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test
    sudo apt update
    sudo apt install -y --allow-unauthenticated gcc-13 g++-13
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 13 --slave /usr/bin/g++ g++ /usr/bin/g++-13
    sudo update-alternatives --set gcc /usr/bin/gcc-13
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev
    sudo update-alternatives --config gcc
    gcc --version
    g++ -v
elif [ "$GCC" == "gcc14" ]; then
    # https://gcc.gnu.org/gcc-14/changes.html
    sudo apt update
    sudo apt install -y software-properties-common
    # Add the Ubuntu Toolchain PPA for newer GCC versions
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt update
    sudo apt install -y --allow-unauthenticated gcc-14 g++-14
    # Configure alternatives to set GCC 14 as default
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 14 \
                             --slave /usr/bin/g++ g++ /usr/bin/g++-14
    sudo update-alternatives --config gcc  # GCC 14 as the default
    gcc --version
    g++ -v
elif [ "$GCC" == "gcc15" ]; then
    # https://gcc.gnu.org/gcc-15/changes.html

    sudo apt update
    sudo apt install -y build-essential flex bison libgmp-dev libmpc-dev libmpfr-dev texinfo wget
    sudo apt-get install -y gperf coreutils libxrandr-dev libxinerama-dev libx11-dev libxcursor-dev libxi-dev libc6-dev

    wget https://ftp.gnu.org/gnu/gcc/gcc-15.0.0/gcc-15.0.0.tar.gz
    tar -xvzf gcc-15.0.0.tar.gz
    cd gcc-15.0.0

    mkdir build
    cd build

    ../configure --prefix=/usr/local/gcc-15 --enable-languages=c,c++ --disable-multilib

    make -j
    sudo make install

    echo "export PATH=/usr/local/gcc-15/bin:\$PATH" >> ~/.bashrc
    source ~/.bashrc
    # sudo apt update
    # sudo apt install -y software-properties-common
    # # Add the Ubuntu Toolchain PPA for newer GCC versions
    # sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    # sudo apt update
    # sudo apt install -y gcc-15 g++-15 # Install experimental GCC and G++ version 15
    # # Configure alternatives to set GCC 15 as default
    # sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 15 \
    #                          --slave /usr/bin/g++ g++ /usr/bin/g++-15
    # sudo update-alternatives --config gcc  # GCC 15 as the default
    # gcc --version
    # g++ -v

else
    echo "GCC version not specified on OPT env var, set one of gcc14, gcc6 or gcc13"
fi

sudo apt-get -y install libasound-dev libjack-dev libpulse-dev oss4-dev #rtaudio

sudo apt-get update && sudo apt-get install -y autoconf libtool automake dos2unix
sudo apt-get update && sudo apt-get install -y cmake build-essential

# sudo apt build-dep cmake

find /lib /usr/lib -name 'libc'

# Download the installer script
# CMAKE_VERSION=3.30.0
# wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh
# chmod +x cmake-${CMAKE_VERSION}-linux-x86_64.sh
# sudo ./cmake-${CMAKE_VERSION}-linux-x86_64.sh --skip-license --prefix=/usr/local
# export PATH="/usr/local/bin:$PATH"

# Verify the installation
cmake --version
sudo apt-get install -y ccache
