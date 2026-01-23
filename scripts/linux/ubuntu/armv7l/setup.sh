#!/usr/bin/env bash
set -e

LINUX_RELEASE=24.04.3

echo "=== Linux ARMv7l (armhf) cross setup ==="
lsb_release -a

sudo apt update -y
sudo apt install -y \
    debootstrap \
    qemu-user-static \
    binfmt-support \
    python3-minimal \
    python3-numpy \
    git \
    cmake \
    gawk \
    pkgconf \
    build-essential \
    ninja-build \
    automake \
    autoconf \
    flex \
    xz-utils \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    mesa-utils mesa-common-dev libgl1-mesa-dev libegl1-mesa-dev

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

UBUNTU_VERSION=$(lsb_release -cs)
if [[ -z "$UBUNTU_VERSION" ]]; then
    echo "Error: Could not detect Ubuntu version. Ensure lsb-release is installed."
    exit 1
fi

# Check if we're running natively on armv7l (armhf)
if [[ "$(uname -m)" == "armv7l" ]]; then
    echo "Native armv7l detected. No need to generate ARM cross apt sources or rootfs."
    SYSROOT="/"
else
    echo "Downloading armhf Linux base"
    IMAGE="ubuntu-base-$LINUX_RELEASE-base-armhf"
    wget https://cdimage.ubuntu.com/ubuntu-base/releases/noble/release/${IMAGE}.tar.gz
    mkdir armhf-rootfs
    sudo tar -xpf ${IMAGE}.tar.gz -C armhf-rootfs
    echo "=== Setup qemu for armhf ==="
    if [ ! -f "/armhf-rootfs/usr/bin/qemu-arm-static" ]; then
        echo "Copying qemu-arm-static into rootfs..."
        sudo cp /usr/bin/qemu-arm-static armhf-rootfs/usr/bin/
    fi
    sudo mount --bind /dev armhf-rootfs/dev
    sudo mount --bind /proc armhf-rootfs/proc
    sudo mount --bind /sys armhf-rootfs/sys
    sudo chroot armhf-rootfs /bin/bash
    SYSROOT="armhf-rootfs"

    OUTPUT_FILE="/etc/apt/sources.list.d/armhf.sources"
    echo "Making sources file for armhf"

    # Generate the .sources content for armhf
    cat <<EOF > $OUTPUT_FILE
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: $UBUNTU_VERSION $UBUNTU_VERSION-updates $UBUNTU_VERSION-backports $UBUNTU_VERSION-security
Components: main restricted universe multiverse
Architectures: armhf armel
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

    echo "Generated armhf .sources file at $OUTPUT_FILE"

    SOURCE_FILE="/etc/apt/sources.list.d/ubuntu.sources"
    awk '
/^Types: deb/ {
    print $0
    getline nextLine
    if (nextLine !~ /^Architectures:/) {
        print "Architectures: amd64"
    }
    print nextLine
    next
}
{ print $0 }
' "$SOURCE_FILE" > "${SOURCE_FILE}.tmp"
    mv "${SOURCE_FILE}.tmp" "$SOURCE_FILE"
    echo "'Architectures: amd64' added where missing after 'Types: deb' in $SOURCE_FILE."
fi

# Add armhf as a foreign architecture if not native
if ! dpkg --print-foreign-architectures | grep -q "armhf"; then
    sudo dpkg --add-architecture armhf
fi
dpkg --print-architecture
dpkg --print-foreign-architectures

# Update package lists
echo "Updating APT package lists..."
sudo apt-get update

echo "Done! ARMHF (armv7l) architecture is ready."

ARCH_SUFFIX=":armhf"
if [[ "$(uname -m)" == "armv7l" ]]; then
    ARCH_SUFFIX=""
fi

echo "Installing ARMHF packages..."
sudo apt-get install -y \
    aptitude$ARCH_SUFFIX \
    gfortran$ARCH_SUFFIX \
    texinfo$ARCH_SUFFIX \
    bison$ARCH_SUFFIX \
    libncurses-dev$ARCH_SUFFIX \
    unzip$ARCH_SUFFIX \
    pkg-config$ARCH_SUFFIX \
    flex$ARCH_SUFFIX \
    openssl$ARCH_SUFFIX \
    pigz$ARCH_SUFFIX \
    autoconf$ARCH_SUFFIX \
    automake$ARCH_SUFFIX \
    figlet$ARCH_SUFFIX \
    gperf$ARCH_SUFFIX \
    libgl1-mesa-dev$ARCH_SUFFIX \
    libglu1-mesa-dev$ARCH_SUFFIX \
    freeglut3-dev$ARCH_SUFFIX \
    libxrandr-dev$ARCH_SUFFIX \
    libxinerama-dev$ARCH_SUFFIX \
    libx11-dev$ARCH_SUFFIX \
    libwayland-dev$ARCH_SUFFIX \
    libxext-dev$ARCH_SUFFIX \
    libxcursor-dev$ARCH_SUFFIX \
    libxi-dev$ARCH_SUFFIX \
    ccache$ARCH_SUFFIX \
    libgles2-mesa-dev$ARCH_SUFFIX \
    libgl1-mesa-dev$ARCH_SUFFIX \
    libegl1-mesa-dev$ARCH_SUFFIX \
    libxkbcommon-dev$ARCH_SUFFIX

if [[ "$(uname -m)" != "armv7l" ]]; then  
    if [[ -d "armhf-rootfs/" ]]; then
        echo "Setting up Linux armhf toolchain inside rootfs..."
        sudo mkdir -p /usr/arm-linux-gnueabihf
        sudo mkdir -p /armhf-rootfs/usr/arm-linux-gnueabihf
        # Link the toolchain inside rootfs (Linux armhf)
        sudo ln -s /armhf-rootfs/usr/bin/arm-linux-gnueabihf-* /usr/arm-linux-gnueabihf/
        sudo ln -s /armhf-rootfs/usr/lib /usr/lib/arm-linux-gnueabihf/
        sudo ln -s /armhf-rootfs/usr/include /usr/arm-linux-gnueabihf/include
        echo "Toolchain linked for Linux armhf at /usr/arm-linux-gnueabihf/"
    else
        echo "Error: /armhf-rootfs/ does not exist. Ensure rootfs is extracted."
        exit 1
    fi
fi

sudo apt install -y \
    binfmt-support \
    python3-minimal \
    python3-numpy \
    git \
    cmake \
    pkgconf \
    build-essential \
    ninja-build \
    xz-utils \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf

if [ -d "/usr/lib/x86_64-linux-gnu" ]; then
    find /usr/lib/x86_64-linux-gnu -name "libGL*"

    lib_files=$(find /usr/lib/x86_64-linux-gnu -name "libGL*")

    if [ -z "$lib_files" ]; then
        echo "No libGL* files found in /usr/lib/x86_64-linux-gnu"
        exit 1
    fi
    echo -e "=== Running ldd on libGL* files ===="
    for file in $lib_files; do
        echo -e "File: $file"
        ldd "$file" || echo "Error: Could not run ldd on $file"
    done
fi
if [ -d "/usr/lib/arm-linux-gnueabihf" ]; then
    find /usr/lib/arm-linux-gnueabihf -name "libGL*"
    find /usr/lib/arm-linux-gnueabihf -name "libwayland*"
else
    echo "Directory /usr/lib/arm-linux-gnueabihf does not exist."
fi

if [ -d "/usr/arm-linux-gnueabihf/bin/pkg-config" ]; then
    echo "Directory /usr/arm-linux-gnueabihf/bin/pkg-config exists"
    find /usr/arm-linux-gnueabihf/bin/pkg-config -name "pkg-config*"
else
    echo "Directory /usr/arm-linux-gnueabihf/bin/pkg-config does not exist."
fi

dpkg -l | grep g++-arm-linux-gnueabihf
dpkg -L libx11-dev:armhf | grep libX11.so
dpkg -L libxext-dev:armhf | grep libXext.so

export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
pkg-config --list-all
