#!/usr/bin/env bash
set -e

echo "=== Linux ARMv6 cross setup using armhf toolchain (ARMv7 arch) ==="
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

# Detect Ubuntu release codename
UBUNTU_VERSION=$(lsb_release -cs)
if [[ -z "$UBUNTU_VERSION" ]]; then
    echo "Error: Could not detect Ubuntu version. Ensure lsb-release is installed."
    exit 1
fi

# For ARMv6, we will not extract a separate rootfs.
# Instead, use the existing armhf toolchain (targeting ARMv7) and adjust compile flags as needed.
if [[ "$(uname -m)" == "armv6l" ]]; then
    echo "Native ARMv6 detected. Using local system and armhf toolchain."
    SYSROOT="/"
else
    echo "Cross-compiling for ARMv6 using armhf toolchain."
    SYSROOT="/"
fi

# Add armhf as a foreign architecture if not already added
if ! dpkg --print-foreign-architectures | grep -q "armhf"; then
    sudo dpkg --add-architecture armhf
fi

echo "Primary architecture: $(dpkg --print-architecture)"
echo "Foreign architectures: $(dpkg --print-foreign-architectures)"

echo "Updating APT package lists..."
sudo apt-get update

echo "Installing ARMHF packages..."
ARCH_SUFFIX=":armhf"
if [[ "$(uname -m)" == "armv6l" ]]; then
    ARCH_SUFFIX=""
fi

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
    libegl1-mesa-dev$ARCH_SUFFIX \
    libxkbcommon-dev$ARCH_SUFFIX

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
    echo "Checking for libGL* files in /usr/lib/x86_64-linux-gnu"
    lib_files=$(find /usr/lib/x86_64-linux-gnu -name "libGL*")
    if [ -z "$lib_files" ]; then
        echo "No libGL* files found in /usr/lib/x86_64-linux-gnu"
        exit 1
    fi
    echo "=== Running ldd on libGL* files ==="
    for file in $lib_files; do
        echo "File: $file"
        ldd "$file" || echo "Error: Could not run ldd on $file"
    done
fi

if [ -d "/usr/lib/arm-linux-gnueabihf" ]; then
    echo "Listing libGL and libwayland files in /usr/lib/arm-linux-gnueabihf"
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
dpkg -L libx11-dev$ARCH_SUFFIX | grep libX11.so
dpkg -L libxext-dev$ARCH_SUFFIX | grep libXext.so

export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
pkg-config --list-all

echo "Setup complete."
echo "Remember: To build for ARMv6, add compiler flags such as '-march=armv6 -mfpu=vfp -mfloat-abi=hard' to your build configuration."
