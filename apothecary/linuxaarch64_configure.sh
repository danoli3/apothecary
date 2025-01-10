# Set the root directory

# Set Raspbian toolchain directory
export RPI_ROOT=$SYSROOT/rootfs
RASP="$RPI_ROOT"


# Set GCC cross-compilation variables
export GCC_PREFIX="aarch64-linux-gnu"
export GCC_VERSION="14.2.0" # Adjust as needed

CMAKE_LIBRARY_ARCHITECTURE=${GCC_PREFIX}

# Update PATH and library paths
export LIBRARY_PATH=${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/lib64:${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/lib:${TOOLCHAIN_ROOT}/lib
export LD_LIBRARY_PATH=${TOOLCHAIN_ROOT}/lib
export PATH=$TOOLCHAIN_ROOT/bin:$LIBRARY_PATH:$PATH

# Define cross-compilation tools
export CC="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-gcc"
export CXX="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-g++"
export CPP="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-cpp"
export AR="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-ar"
export AS="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-as"
export RANLIB="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-ranlib"
export FC="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-gfortran"
export LD="${TOOLCHAIN_ROOT}/bin/${GCC_PREFIX}-ld"

# GCC plugin path for LTO
GCCPATH="$RASP/libexec/gcc/${GCC_PREFIX}/${GCC_VERSION}"
export ARFLAGS="--plugin ${GCCPATH}/liblto_plugin.so"
export RANLIBFLAGS="--plugin ${GCCPATH}/liblto_plugin.so"

# GStreamer version for dependencies
export GST_VERSION="1.0"
# Compiler flags for ARM64
export CFLAGS="--sysroot=${RPI_ROOT} \
    -I${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/include \
    -I${TOOLCHAIN_ROOT}/lib/gcc/${GCC_PREFIX}/${GCC_VERSION}/include \
    -DSTANDALONE -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE \
    -D_FILE_OFFSET_BITS=64 \
    -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST"

# Linker flags for ARM64
export LDFLAGS="--sysroot=${RPI_ROOT} \
    -Wl,-rpath-link,${RPI_ROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -L${RPI_ROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -Wl,-rpath-link,${RPI_ROOT}/usr/lib64/${CMAKE_LIBRARY_ARCHITECTURE} \
    -L${RPI_ROOT}/usr/lib64/${CMAKE_LIBRARY_ARCHITECTURE} \
    -Wl,-rpath-link,${TOOLCHAIN_ROOT}/${GCC_PREFIX}/lib64 \
    -L${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/lib64 \
    -L${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/lib \
    -L${TOOLCHAIN_ROOT}/${GCC_PREFIX}/libc/usr/lib64 \
    -L${TOOLCHAIN_ROOT}/lib/gcc/${GCC_PREFIX}/${GCC_VERSION}"



[ -d "${RPI_ROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}" ] && ls -la "${RPI_ROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}" || echo "Directory not found: ${RPI_ROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}"
[ -d "${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/lib64" ] && ls -la "${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/lib64" || echo "Directory not found: ${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/lib64"
[ -d "${TOOLCHAIN_ROOT}/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${GCC_VERSION}" ] && ls -la "${TOOLCHAIN_ROOT}/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${GCC_VERSION}" || echo "Directory not found: ${TOOLCHAIN_ROOT}/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${GCC_VERSION}"

# Host system for cross-compilation
export HOST="${GCC_PREFIX}"

# Debugging output
echo "--------------------"
echo "openFrameworks apothecary Cross Compiler: $GCC_PREFIX"
echo "Using GCC Version: $GCC_VERSION"
echo "Library Path: $LIBRARY_PATH"
echo "SYSROOT Path: $RASP"
echo "Toolchain ROOT: $TOOLCHAIN_ROOT"
echo "GCC Path: $GCCPATH"
echo "LDFLAGS : $LDFLAGS"
echo "CFLAGS : $CFLAGS"
echo "Path: $PATH"
echo "--------------------"