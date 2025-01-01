# Set the root directory
export RPI_ROOT=$SYSROOT
# Set Raspbian toolchain directory
RASP="$RPI_ROOT/raspbianpi3ab45"


# Set GCC cross-compilation variables
export GCC_PREFIX="arm-linux-gnueabihf"
export GCC_VERSION="14.2.0" # Adjust as needed

export LIBRARY_PATH=${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/lib
export PATH=$RASP/bin:$PATH

# Define cross-compilation tools
export CC="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-gcc"
export CXX="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-g++"
export CPP="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-cpp"
export AR="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-ar"
export RANLIB="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-ranlib"
export FC="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-gfortran"
export LD="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-ld"

# GCC plugin path for LTO
GCCPATH="$RASP/libexec/gcc/${GCC_PREFIX}/${GCC_VERSION}"
export ARFLAGS="--plugin $GCCPATH/liblto_plugin.so"
export RANLIBFLAGS="--plugin $GCCPATH/liblto_plugin.so"

# Package configuration path
export PKG_CONFIG_PATH="$SYSROOT/usr/lib/$GCC_PREFIX/pkgconfig:$SYSROOT/usr/share/pkgconfig:$SYSROOT/usr/lib/pkgconfig"

# Compiler flags for ARMv7
export CFLAGS="--sysroot=${SYSROOT} \
    -I$SYSROOT/usr/include \
    -I$SYSROOT/opt/vc/include \
    -I$SYSROOT/opt/vc/include/IL \
    -I$SYSROOT/opt/vc/include/interface/vcos/pthreads \
    -I$SYSROOT/opt/vc/include/interface/vmcs_host/linux \
    -I$SYSROOT/opt/vc/lib \
    -march=armv7-a -mfpu=vfp -mfloat-abi=hard \
    -fPIC -ftree-vectorize -Wno-psabi -pipe \
    -DSTANDALONE -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE \
    -D_FILE_OFFSET_BITS=64 -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS \
    -DTARGET_POSIX -DHAVE_LIBOPENMAX=2 -DOMX -DOMX_SKIP64BIT -DUSE_EXTERNAL_OMX \
    -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST -DUSE_VCHIQ_ARM"

# Linker flags for ARMv7
export LDFLAGS="--sysroot=${SYSROOT} \
    -L$SYSROOT/usr/lib \
    -L$SYSROOT/usr/lib/arm-linux-gnueabihf \
    -L${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/lib \
    -L$SYSROOT/opt/vc/lib/"

# Host system for cross-compilation
export HOST="${GCC_PREFIX}"

# Debugging output
echo "--------------------"
echo "openFrameworks apothecary Cross Compiler: $GCC_PREFIX"
echo "Using GCC Version: $GCC_VERSION"
echo "Library Path: $LIBRARY_PATH"
echo "Toolchain Path: $RASP"
echo "GCC Path: $GCCPATH"
echo "LDFLAGS : $LDFLAGS"
echo "CFLAGS : $CFLAGS"
echo "Path: $PATH"
echo "--------------------"
