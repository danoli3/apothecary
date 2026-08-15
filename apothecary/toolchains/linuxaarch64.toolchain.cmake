# Raspberry Pi OS 64-bit toolchain (ARCH=aarch64).
# Official builds use host GCC 10 + a bookworm arm64 SYSROOT.
cmake_minimum_required(VERSION 3.15)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_LIBRARY_ARCHITECTURE aarch64-linux-gnu)
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
        set(M_CPU cortex-a53)
    endif()
endif()

if(NOT DEFINED SYSROOT)
    if(DEFINED ENV{SYSROOT})
        set(SYSROOT $ENV{SYSROOT})
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
        set(SYSROOT "/")
    else()
        set(SYSROOT "/opt/rpi-arm64-sysroot")
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
elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "aarch64|arm64" AND SYSROOT STREQUAL "/")
    find_program(CMAKE_C_COMPILER NAMES gcc-10 gcc PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
    find_program(CMAKE_CXX_COMPILER NAMES g++-10 g++ PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
else()
    find_program(CMAKE_C_COMPILER
        NAMES aarch64-linux-gnu-gcc-10 aarch64-linux-gnu-gcc
        PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin
        NO_DEFAULT_PATH)
    find_program(CMAKE_CXX_COMPILER
        NAMES aarch64-linux-gnu-g++-10 aarch64-linux-gnu-g++
        PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin
        NO_DEFAULT_PATH)
endif()

find_program(CMAKE_AR NAMES aarch64-linux-gnu-ar ar PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_RANLIB NAMES aarch64-linux-gnu-ranlib ranlib PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_STRIP NAMES aarch64-linux-gnu-strip strip PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_LINKER NAMES aarch64-linux-gnu-ld ld PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_NM NAMES aarch64-linux-gnu-nm nm PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_OBJCOPY NAMES aarch64-linux-gnu-objcopy objcopy PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)
find_program(CMAKE_OBJDUMP NAMES aarch64-linux-gnu-objdump objdump PATHS /usr/bin ${TOOLCHAIN_ROOT}/bin)

if(NOT CMAKE_C_COMPILER)
    message(FATAL_ERROR "C compiler not found for Raspberry Pi aarch64 (need aarch64-linux-gnu-gcc-10)")
endif()
if(NOT CMAKE_CXX_COMPILER)
    message(FATAL_ERROR "C++ compiler not found for Raspberry Pi aarch64 (need aarch64-linux-gnu-g++-10)")
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
    "${CMAKE_SYSROOT}/lib64"
    "${CMAKE_SYSROOT}/lib/aarch64-linux-gnu"
    "${CMAKE_SYSROOT}/usr/lib"
    "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu")
    if(EXISTS "${_libdir}")
        string(APPEND EXTRA_LINKS " -Wl,-rpath-link,${_libdir} -L${_libdir}")
    endif()
endforeach()

set(RPI_ARCH_FLAGS "-march=armv8-a -mtune=${M_CPU} -fPIC")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --sysroot=${CMAKE_SYSROOT} ${RPI_ARCH_FLAGS} ${EXTRA_LINKS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --sysroot=${CMAKE_SYSROOT} ${RPI_ARCH_FLAGS} ${EXTRA_LINKS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --sysroot=${CMAKE_SYSROOT} ${EXTRA_LINKS}")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --sysroot=${CMAKE_SYSROOT} -fPIC ${EXTRA_LINKS}")

if(DEFINED ENV{PKG_CONFIG_LIBDIR})
    set(ENV{PKG_CONFIG_LIBDIR} "$ENV{PKG_CONFIG_LIBDIR}")
else()
    set(ENV{PKG_CONFIG_LIBDIR} "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig")
endif()
set(ENV{PKG_CONFIG_SYSROOT_DIR} "${CMAKE_SYSROOT}")

message(STATUS "Raspberry Pi aarch64 toolchain")
message(STATUS "  GCC_VERSION=${GCC_VERSION}")
message(STATUS "  CMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
message(STATUS "  CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}")
message(STATUS "  CMAKE_SYSROOT=${CMAKE_SYSROOT}")
message(STATUS "  M_CPU=${M_CPU}")
