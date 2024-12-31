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

installPackages(){
    IS_UBUNTU=`uname -a | grep Ubuntu > /dev/null; echo $?`
    UBUNTU_VERSION=`lsb_release -r | awk '{ print $2 }'`
    if [ $IS_UBUNTU -eq 0 ] && [ "$UBUNTU_VERSION" == "14.04" ]; then
        echo "installing ppa"
        #sudo add-apt-repository ppa:dns/gnu -y
    else
        echo "$UBUNTU_VERSION doesn\'t need ppa"
    fi
    sudo apt-get update -q
    sudo apt-get -y install gcc-arm-linux-gnueabihf
    sudo apt-get -y install multistrap unzip coreutils gperf build-essential
    sudo apt-get install -y pkgconf rsync 
    #workaround for https://bugs.launchpad.net/ubuntu/+source/multistrap/+bug/1313787
    if [ $IS_UBUNTU -eq 0 ] && [ "$UBUNTU_VERSION"=="14.04" ]; then
        sudo sed -i s/\$forceyes//g /usr/sbin/multistrap
    fi
}

createRaspbianImg(){
    #needed since Ubuntu 18.04 - allow non https repositories
    mkdir -p raspbian/etc/apt/apt.conf.d/
	echo 'Acquire::AllowInsecureRepositories "true";' | sudo tee raspbian/etc/apt/apt.conf.d/90insecure
    multistrap -a armhf -d raspbian -f multistrap.conf
}

downloadToolchain(){
    wget "https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains/Buster/GCC%2014.2.0/Raspberry%20Pi%203A%2B%2C%203B%2B%2C%204%2C%205/cross-gcc-14.2.0-pi_3%2B.tar.gz/download" -O cross-gcc-14.2.0-pi_3+.tar.gz && tar xf cross-gcc-14.2.0-pi_3+.tar.gz && rm cross-gcc-14.2.0-pi_3+.tar.gz && mv cross-pi-gcc-14.2.0-2 raspbianpi3ab45

}

downloadFirmware(){
    echo "no firmware"
    # wget -nv https://github.com/raspberrypi/firmware/archive/master.zip -O firmware.zip
    # unzip -q firmware.zip
    # cp -r firmware-master/opt raspbian/
    # rm -r firmware-master
    # rm firmware.zip
}

relativeSoftLinks(){
    for link in $(ls -la | grep "\-> /" | sed "s/.* \([^ ]*\) \-> \/\(.*\)/\1->\/\2/g"); do
        lib=$(echo $link | sed "s/\(.*\)\->\(.*\)/\1/g");
        link=$(echo $link | sed "s/\(.*\)\->\(.*\)/\2/g");
        rm $lib
        ln -s ../../..$link $lib
    done

    for f in *; do
        error=$(grep " \/lib/" $f > /dev/null 2>&1; echo $?)
        if [ $error -eq 0 ]; then
            sed -i "s/ \/lib/ ..\/..\/..\/lib/g" $f
            sed -i "s/ \/usr/ ..\/..\/..\/usr/g" $f
        fi
    done
}

if [[ $(uname -m) != armv* ]]; then

	ROOT=$( cd "$(dirname "$0")" ; pwd -P )
	echo $ROOT
	cd $ROOT
	installPackages
	# createRaspbianImg
	# downloadFirmware
    downloadToolchain

	
fi
