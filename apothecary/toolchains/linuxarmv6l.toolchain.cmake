# Raspberry Pi OS 32-bit ARMv6 toolchain (ARCH=armv6l) — Pi 1 / Zero.
# Official builds use host GCC 10 + a bookworm armhf SYSROOT with v6 flags.
cmake_minimum_required(VERSION 3.15)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_LIBRARY_ARCHITECTURE arm-linux-gnueabihf)
set(CMAKE_VERBOSE_MAKEFILE ON)

if(NOT DEFINED GCC_VERSION)
    if(DEFINED ENV{GCC_VERSION})
        set(GCC_VERSION $ENV{GCC_VERSION})
    else()
        set(GCC_VERSION 10)
    endif()
endif()

if(NOT DEFINED M_CPU)
    if(DEFINED ENV{M_CPU})
        set(M_CPU $ENV{M_CPU})
    else()
        set(M_CPU arm1176jzf-s)
    endif()
endif()

if(NOT DEFINED SYSROOT)
    if(DEFINED ENV{SYSROOT})
        set(SYSROOT $ENV{SYSROOT})
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "armv6l")
        set(SYSROOT "/")
    else()
        set(SYSROOT "/opt/rpi-armv6l-sysroot")
        message(WARNING "SYSROOT not specified. Defaulting to ${SYSROOT}")
    endif()
endif()

if(NOT DEFINED TOOLCHAIN_ROOT)
    if(DEFINED ENV{TOOLCHAIN_ROOT})
        set(TOOLCHAIN_ROOT $ENV{TOOLCHAIN_ROOT})
    else()
        set(TOOLCHAIN_ROOT "/usr")
    endif()
endif()

if(DEFINED ENV{CC} AND DEFINED ENV{CXX})
    set(CMAKE_C_COMPILER "$ENV{CC}" CACHE FILEPATH "" FORCE)
    set(CMAKE_CXX_COMPILER "$ENV{CXX}" CACHE FILEPATH "" FORCE)
elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "armv6l" AND SYSROOT STREQUAL "/")
    find_program(CMAKE_C_COMPILER NAMES gcc-10 gcc PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
    find_program(CMAKE_CXX_COMPILER NAMES g++-10 g++ PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
else()
    find_program(CMAKE_C_COMPILER
        NAMES arm-linux-gnueabihf-gcc-10 arm-linux-gnueabihf-gcc
        PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin
        NO_DEFAULT_PATH)
    find_program(CMAKE_CXX_COMPILER
        NAMES arm-linux-gnueabihf-g++-10 arm-linux-gnueabihf-g++
        PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin
        NO_DEFAULT_PATH)
endif()

find_program(CMAKE_AR NAMES arm-linux-gnueabihf-ar ar PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_RANLIB NAMES arm-linux-gnueabihf-ranlib ranlib PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_STRIP NAMES arm-linux-gnueabihf-strip strip PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_LINKER NAMES arm-linux-gnueabihf-ld ld PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_NM NAMES arm-linux-gnueabihf-nm nm PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_OBJCOPY NAMES arm-linux-gnueabihf-objcopy objcopy PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_OBJDUMP NAMES arm-linux-gnueabihf-objdump objdump PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)

if(NOT CMAKE_C_COMPILER)
    message(FATAL_ERROR "C compiler not found for Raspberry Pi armv6l (need arm-linux-gnueabihf-gcc-10)")
endif()
if(NOT CMAKE_CXX_COMPILER)
    message(FATAL_ERROR "C++ compiler not found for Raspberry Pi armv6l (need arm-linux-gnueabihf-g++-10)")
endif()

set(CMAKE_SYSROOT "${SYSROOT}")
set(CMAKE_FIND_ROOT_PATH "${SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

if(NOT DEFINED C_STANDARD)
    set(C_STANDARD 17)
endif()
if(NOT DEFINED CPP_STANDARD)
    set(CPP_STANDARD 17)
endif()
set(CMAKE_C_STANDARD ${C_STANDARD})
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD ${CPP_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(EXTRA_LINKS "")
foreach(_libdir
    "${CMAKE_SYSROOT}/lib"
    "${CMAKE_SYSROOT}/lib/arm-linux-gnueabihf"
    "${CMAKE_SYSROOT}/usr/lib"
    "${CMAKE_SYSROOT}/usr/lib/arm-linux-gnueabihf")
    if(EXISTS "${_libdir}")
        string(APPEND EXTRA_LINKS " -Wl,-rpath-link,${_libdir} -L${_libdir}")
    endif()
endforeach()

# Keep this strictly ARMv6. Ubuntu's armhf gcc defaults to v7.
set(RPI_ARCH_FLAGS "-march=armv6zk -mcpu=${M_CPU} -mfpu=vfp -mfloat-abi=hard -fPIC")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --sysroot=${CMAKE_SYSROOT} ${RPI_ARCH_FLAGS} ${EXTRA_LINKS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --sysroot=${CMAKE_SYSROOT} ${RPI_ARCH_FLAGS} ${EXTRA_LINKS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --sysroot=${CMAKE_SYSROOT} ${EXTRA_LINKS}")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --sysroot=${CMAKE_SYSROOT} -fPIC ${EXTRA_LINKS}")

if(DEFINED ENV{PKG_CONFIG_LIBDIR})
    set(ENV{PKG_CONFIG_LIBDIR} "$ENV{PKG_CONFIG_LIBDIR}")
else()
    set(ENV{PKG_CONFIG_LIBDIR} "${CMAKE_SYSROOT}/usr/lib/arm-linux-gnueabihf/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig")
endif()
set(ENV{PKG_CONFIG_SYSROOT_DIR} "${CMAKE_SYSROOT}")

message(STATUS "Raspberry Pi armv6l toolchain")
message(STATUS "  GCC_VERSION=${GCC_VERSION}")
message(STATUS "  CMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
message(STATUS "  CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}")
message(STATUS "  CMAKE_SYSROOT=${CMAKE_SYSROOT}")
message(STATUS "  M_CPU=${M_CPU}")
