cmake_minimum_required(VERSION 3.15)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)

# Change to ARMv7
set(CMAKE_SYSTEM_PROCESSOR armv7)
set(CMAKE_LIBRARY_ARCHITECTURE arm-linux-gnueabihf)
set(GCC_VERSION 14.2.0)

set(tools ${TOOLCHAIN_ROOT}) # warning change toolchain path here.
set(rootfs_dir ${SYSROOT}/rootfs) # warning change compiled rootfs path here.

set(CMAKE_FIND_ROOT_PATH ${rootfs_dir})
set(CMAKE_SYSROOT ${rootfs_dir})

if(NOT DEFINED C_STANDARD)
    set(C_STANDARD 17) # Default to C17
endif()
if(NOT DEFINED CPP_STANDARD)
    set(CPP_STANDARD 17) # Default to C++17
endif()
set(CMAKE_C_STANDARD ${C_STANDARD})
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD ${CPP_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(EXTRA_LINKS "-Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -L${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -Wl,-rpath-link,${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/lib \
    -L${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/lib
    -L${TOOLCHAIN_ROOT}/lib \
    -L${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/libc/lib \
    -Wl,-rpath-link,${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/libc/usr/lib \
    -L${TOOLCHAIN_ROOT}/${CMAKE_LIBRARY_ARCHITECTURE}/libc/usr/lib \
    -L${TOOLCHAIN_ROOT}/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${GCC_VERSION}")

# Update linker flags for ARMv7
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fPIC ${EXTRA_LINKS}")

# Update compiler flags for ARMv7
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --sysroot=${CMAKE_SYSROOT} -fPIC -march=armv7-a -mfpu=vfp -mcpu=cortex-a7 -mfloat-abi=hard ${EXTRA_LINKS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --sysroot=${CMAKE_SYSROOT} -fPIC -march=armv7-a -mfpu=vfp -mcpu=cortex-a7 -mfloat-abi=hard ${EXTRA_LINKS}")

# NEON
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mfpu=neon")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mfpu=neon")

# Compiler Binary
set(BIN_PREFIX "${TOOLCHAIN_ROOT}/bin/")

find_program(CMAKE_C_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-gcc PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_CXX_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-g++ PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_LINKER ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-ld PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_AR ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-ar PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_NM ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-nm PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_RANLIB ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-ranlib PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_STRIP ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-strip PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_OBJCOPY ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-objcopy PATHS "${TOOLCHAIN_ROOT}/bin/")
find_program(CMAKE_OBJDUMP ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu-objdump PATHS "${TOOLCHAIN_ROOT}/bin/")

if(NOT EXISTS ${CMAKE_C_COMPILER})
    message(FATAL_ERROR "C Compiler not found: ${CMAKE_C_COMPILER}")
endif()

if(NOT EXISTS ${CMAKE_CXX_COMPILER})
    message(FATAL_ERROR "C++ Compiler not found: ${CMAKE_CXX_COMPILER}")
endif()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
