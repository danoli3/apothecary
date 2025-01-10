# Linux Ubuntu 64-bit Toolchain File

# Specify the system
set(CMAKE_SYSTEM_NAME Linux)        # Cross-compilation target system
set(CMAKE_SYSTEM_PROCESSOR x86_64) # Architecture (64-bit)

set(CMAKE_VERBOSE_MAKEFILE ON)

# GCC Version (Set this variable when invoking CMake)
if(NOT DEFINED GCC_VERSION)
    message(FATAL_ERROR "Please specify GCC_VERSION (e.g., -DGCC_VERSION=14)")
endif()

# Path to GCC 
if(NOT DEFINED GCC_PATH)
    set(GCC_PATH "/usr/bin") # Default GCC path
endif()

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

# Compiler Binary Paths
set(CMAKE_C_COMPILER "${GCC_PATH}/gcc-${GCC_VERSION}")
set(CMAKE_CXX_COMPILER "${GCC_PATH}/g++-${GCC_VERSION}")

# Check for the existence of the specified GCC version
if(NOT EXISTS ${CMAKE_C_COMPILER})
    message(FATAL_ERROR "C Compiler not found: ${CMAKE_C_COMPILER}")
endif()
if(NOT EXISTS ${CMAKE_CXX_COMPILER})
    message(FATAL_ERROR "C++ Compiler not found: ${CMAKE_CXX_COMPILER}")
endif()

# Paths to system libraries and includes
set(CMAKE_SYSROOT "/usr") # Base system path for includes and libraries
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Compiler and linker flags
set(CMAKE_C_FLAGS "-fPIC -O3 -Wall -Wextra -march=x86-64 -mtune=generic")
set(CMAKE_CXX_FLAGS "-fPIC -O3 -Wall -Wextra -std=c++${CPP_STANDARD} -march=x86-64 -mtune=generic")
set(CMAKE_EXE_LINKER_FLAGS "-fPIE -pie")
set(CMAKE_SHARED_LINKER_FLAGS "-shared -fPIC")


message(STATUS "Using GCC Version: ${GCC_VERSION}")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "System Root: ${CMAKE_SYSROOT}")
