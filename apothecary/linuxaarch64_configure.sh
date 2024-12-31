# Set the root directory

# Set Raspbian toolchain directory
export RPI_ROOT=$SYSROOT
RASP="$RPI_ROOT/raspbian"

# Update PATH and library paths
export PATH=$RASP/bin:$PATH
export LD_LIBRARY_PATH=$RASP/lib

# Set GCC cross-compilation variables
export GCC_PREFIX="aarch64-linux-gnu"
export GCC_VERSION="14.2.0" # Adjust as needed

# Define cross-compilation tools
export AR="${GCC_PREFIX}-gcc-ar"
export CC="${GCC_PREFIX}-gcc"
export CXX="${GCC_PREFIX}-g++"
export CPP="${GCC_PREFIX}-cpp"
export FC="${GCC_PREFIX}-gfortran"
export RANLIB="${GCC_PREFIX}-gcc-ranlib"
export LD="$CXX"

# GCC plugin path for LTO
GCCPATH="$RASP/libexec/gcc/${GCC_PREFIX}/${GCC_VERSION}"
export ARFLAGS="--plugin $GCCPATH/liblto_plugin.so"
export RANLIBFLAGS="--plugin $GCCPATH/liblto_plugin.so"

# GStreamer version for dependencies
export GST_VERSION="1.0"

# Package configuration path
export PKG_CONFIG_PATH="$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/lib/$GCC_PREFIX/pkgconfig:$SYSROOT/usr/share/pkgconfig"

# Compiler flags for ARM64
export CFLAGS="--sysroot=${SYSROOT} \
    -I${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/include \
    -I${TOOLCHAIN_ROOT}/lib/gcc/${GCC_PREFIX}/${GCC_VERSION}/include \
    -I$SYSROOT/opt/vc/include \
    -I$SYSROOT/opt/vc/include/IL \
    -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST"

# Linker flags for ARM64
export LDFLAGS="--sysroot=${SYSROOT} \
    -L${SYSROOT}/usr/lib/${GCC_PREFIX} \
    -L${SYSROOT}/usr/lib/aarch64-linux-gnu \
    -L${TOOLCHAIN_ROOT}/aarch64-linux-gnu/lib64 \
    -L${TOOLCHAIN_ROOT}/aarch64-linux-gnu/libc/lib64 \
    -L${TOOLCHAIN_ROOT}/lib/gcc/${GCC_PREFIX}/${GCC_VERSION} \
    -L${SYSROOT}/lib/${GCC_PREFIX}"

# Host system for cross-compilation
export HOST="${GCC_PREFIX}"

# Debugging output
echo "Using GCC Version: $GCC_VERSION"
echo "Toolchain Path: $RASP"
echo "GCC Path: $GCCPATH"
