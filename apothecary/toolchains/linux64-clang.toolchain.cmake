# Set the system name to Linux to indicate the target environment
set(CMAKE_SYSTEM_NAME Linux)

# Set the processor architecture
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Specify the C and C++ compilers
set(CMAKE_C_COMPILER "clang")
set(CMAKE_CXX_COMPILER "clang++")

# Optionally, set compiler flags
set(CMAKE_C_FLAGS "-m64")
set(CMAKE_CXX_FLAGS "-m64")