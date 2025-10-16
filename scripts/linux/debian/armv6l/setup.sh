#!/usr/bin/env bash
set -e

DEBIAN_RELEASE=bookworm  # Debian 12 stable
ARCH_TRIPLE=arm-linux-gnueabi  # <-- armel (not gnueabihf)
DEB_ARCH=armel
SYSROOT="/"

echo "=== Debian ARMv6 (armel) cross setup ==="
cat /etc/os-release

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
    gcc-${ARCH_TRIPLE} \
    g++-${ARCH_TRIPLE} \
    binutils-${ARCH_TRIPLE}

# Run as root check
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Detect native ARMv6
if [[ "$(uname -m)" == "armv6l" ]]; then
    echo "Native ARMv6 detected. Using local system."
else
    echo "Cross-compiling for ARMv6 using ${ARCH_TRIPLE} toolchain."
fi

# Add armel as foreign architecture if needed
if ! dpkg --print-foreign-architectures | grep -q "${DEB_ARCH}"; then
    sudo dpkg --add-architecture "${DEB_ARCH}"
fi

echo "Primary architecture: $(dpkg --print-architecture)"
echo "Foreign architectures: $(dpkg --print-foreign-architectures)"

sudo apt-get update

echo "Installing core ${DEB_ARCH} packages..."
ARCH_SUFFIX=":${DEB_ARCH}"
sudo apt-get install -y \
    aptitude$ARCH_SUFFIX \
    pkg-config$ARCH_SUFFIX \
    autoconf$ARCH_SUFFIX \
    automake$ARCH_SUFFIX \
    libncurses-dev$ARCH_SUFFIX \
    bison$ARCH_SUFFIX \
    flex$ARCH_SUFFIX \
    gperf$ARCH_SUFFIX \
    texinfo$ARCH_SUFFIX \
    figlet$ARCH_SUFFIX \
    openssl$ARCH_SUFFIX \
    unzip$ARCH_SUFFIX \
    libx11-dev$ARCH_SUFFIX \
    libxext-dev$ARCH_SUFFIX \
    libxi-dev$ARCH_SUFFIX \
    libxrandr-dev$ARCH_SUFFIX \
    libxinerama-dev$ARCH_SUFFIX \
    libxcursor-dev$ARCH_SUFFIX \
    libwayland-dev$ARCH_SUFFIX \
    libgles2-mesa-dev$ARCH_SUFFIX \
    libegl1-mesa-dev$ARCH_SUFFIX \
    ccache$ARCH_SUFFIX

echo "Setting pkg-config and sysroot..."
export PKG_CONFIG_PATH=/usr/lib/${ARCH_TRIPLE}/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=/usr/lib/${ARCH_TRIPLE}/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYSROOT}

echo "Testing pkg-config..."
pkg-config --list-all | head -20

echo "Setup complete."
echo "Use CFLAGS: -march=armv6 -mfloat-abi=softfp -mfpu=vfp -mtune=arm1176jzf-s"
