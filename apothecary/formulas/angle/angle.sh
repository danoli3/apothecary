#!/usr/bin/env bash
#
# ANGLE - Almost Native Graphics Layer Engine
# (Example formula for building ANGLE for multiple platforms using GN/Ninja)
#
# Supported platforms: vs, osx, emscripten, ios, watchos, catos, xros, tvos, linux, android

FORMULA_TYPES=("vs" "osx" "emscripten" "ios" "watchos" "catos" "xros" "tvos" "linux" "android")
FORMULA_DEPENDS=()  # Add any dependency formulas if needed

VER_FULL="chromium/7066"
VER=${VER_FULL#*/}

BUILD_ID=1
DEFINES=""
FRAMEWORKS=""

GIT_URL=https://github.com/google/angle/archive/refs/heads/$VER_FULL.tar.gz
GIT_TAG=v$VER

function download() {
#     . "$DOWNLOADER_SCRIPT"
#     downloader ${GIT_URL}
#     tar -xf $VER.tar.gz
#     mv "angle-chromium-$VER" angle
#     rm -f $VER.tar.gz

    if [ -d "angle" ]; then
        echo "Removing existing ANGLE directory..."
        rm -rf angle
    fi

    echo "Cloning ANGLE repository from ${GIT_URL}..."
    
    # Clone the repository with submodules
    git clone --recursive --depth=1 --branch "$VER_FULL" https://github.com/google/angle.git

    if [ $? -ne 0 ]; then
        echo "Failed to clone ANGLE repository!"
        exit 1
    fi

    cd angle || exit

    echo "Checking out branch/tag: $VER_FULL..."
    git fetch --tags
    git checkout "$VER_FULL"

    # # Ensure submodules are fully updated
    echo "Updating ANGLE submodules..."
    git submodule update --init --recursive
    LIMIT_SUBS=false
    if [ "$LIMIT_SUBS" == true ]; then
        case "$TYPE" in
            vs)  # Windows (Direct3D, Vulkan)
                REQUIRED_SUBMODULES=(
                    "build"
                    "buildtools"
                    "third_party/dawn"
                    "third_party/glslang/src"
                    "third_party/vulkan-headers/src"
                    "third_party/vulkan-loader/src"
                    "third_party/vulkan-tools/src"
                    "third_party/vulkan-validation-layers/src"
                    "third_party/vulkan_memory_allocator"
                    "tools/python"
                )
                ;;
            osx|ios|tvos|xros|catos|watchos)  # Apple platforms (Metal, OpenGL)
                REQUIRED_SUBMODULES=(
                    "build"
                    "buildtools"
                    "third_party/dawn"
                    "third_party/glslang/src"
                    "third_party/EGL-Registry/src"
                    "third_party/OpenGL-Registry/src"
                    "third_party/spirv-tools/src"
                    "tools/python"
                    "tools/clang"
                )
                ;;
            android)  # Android (Vulkan, GLES)
                REQUIRED_SUBMODULES=(
                    "build"
                    "buildtools"
                    "third_party/android_build_tools"
                    "third_party/android_deps"
                    "third_party/android_platform"
                    "third_party/android_sdk"
                    "third_party/dawn"
                    "third_party/glslang/src"
                    "third_party/vulkan-headers/src"
                    "third_party/vulkan-loader/src"
                    "third_party/vulkan-tools/src"
                    "third_party/vulkan-validation-layers/src"
                    "third_party/vulkan_memory_allocator"
                    "tools/python"
                    "tools/clang"
                    "tools/android"
                )
                ;;
            linux)  # Linux (OpenGL, Vulkan)
                REQUIRED_SUBMODULES=(
                    "build"
                    "buildtools"
                    "third_party/dawn"
                    "third_party/glslang/src"
                    "third_party/EGL-Registry/src"
                    "third_party/OpenGL-Registry/src"
                    "third_party/spirv-tools/src"
                    "third_party/wayland"
                    "third_party/libdrm/src"
                    "tools/python"
                )
                ;;
            emscripten)  # WebAssembly (WebGL)
                REQUIRED_SUBMODULES=(
                    "build"
                    "buildtools"
                    "third_party/dawn"
                    "third_party/glslang/src"
                    "third_party/EGL-Registry/src"
                    "third_party/OpenGL-Registry/src"
                    "third_party/spirv-tools/src"
                    "tools/python"
                )
                ;;
            *)
                echo "Unsupported TYPE: $TYPE"
                exit 1
                ;;
        esac

        echo "Initializing required submodules..."
        for submodule in "${REQUIRED_SUBMODULES[@]}"; do
            git submodule update --init --recursive "$submodule"
        done
    fi

    cd ..

}




function prepare() {
    # If needed, copy any patch files or configuration scripts.
    # For GN, ANGLE already includes the necessary BUILD.gn files.
    cp -v "$FORMULA_DIR"/*.txt ./
    echo "Listing angle directory contents:"
    ls -lR .

    if ! command -v gn &> /dev/null; then
        rm -rf depot_tools
        if [ ! -d "depot_tools" ]; then
            echo "GN not found. Installing depot_tools..."
            git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
        else
            echo "Depot_tools already exists. Updating..."
            cd depot_tools && git pull && cd ..
        fi
    fi
    export "PATH=$PWD/depot_tools:$PATH"

    if command -v python3 &>/dev/null; then
        PYTHON_BIN="python3"
    elif command -v python &>/dev/null; then
        PYTHON_BIN="python"
    elif command -v py &>/dev/null; then
        PYTHON_BIN="py -3"
    else
        echo "Error: Python 3 is not installed or not in PATH."
        exit 1
    fi

    # Run Python script using detected Python binary
    echo "Using Python binary: $PYTHON_BIN"
    $PYTHON_BIN scripts/bootstrap.py
    
    gclient sync

    # if [[ "$TYPE" =~ ^(linux)$ ]]; then
    #     ./build/install-build-deps.sh
    # fi
}

function load() {
    if [ -f "$LOAD_SCRIPT" ]; then
        source "$LOAD_SCRIPT"
    else
        return 0
    fi
    LOAD_RESULT=$(loadsave "${TYPE}" "angle" "${ARCH}" "${VER}" "$LIBS_DIR_REAL/$1/lib/$TYPE/$PLATFORM" "${BUILD_ID}")
    PREBUILT=$(echo "$LOAD_RESULT" | tail -n 1)
    if [ "$PREBUILT" -eq 1 ]; then
        echo 1
    else
        echo 0
    fi
}

function build() {
    LIBS_ROOT=$(realpath "$LIBS_DIR")
    
    if [[ $FORCE_DOWNLOAD -eq 0 ]] && [[ $USE_SAVE == 1 ]]; then
        result=$(load "angle" | tail -n 1)
        echoInfo "===Build angle - Checking if Precompiled binary :[$result]==="
        if [ $result -eq 1 ]; then
            echoInfo "===Build \"angle\" Precompiled binary validated. Skipping updateFormula==="
            return 0
        else
            echoInfo "===Build Precompiled not found or outdated. Continue updateFormula for \"angle\"==="
        fi
    else
        echoInfo "===Build Not using cache: [FORCE_DOWNLOAD=$FORCE_DOWNLOAD] [USE_SAVE=$USE_SAVE] for updateFormula \"angle\"==="
    fi

    rm -rf build_${TYPE}_${ARCH}
    mkdir -p "build_${TYPE}_${ARCH}"

    rm -rf out/Debug
    mkdir -p "out/Debug"

    rm -rf out/Release
    mkdir -p "out/Release"

    export DEPOT_TOOLS_UPDATE=0
    if [[ ":$PATH:" != *":$PWD/depot_tools:"* ]]; then
        export PATH="$PWD/depot_tools:$PATH"
        echo "Added depot_tools to PATH"
    else
        echo "depot_tools is already in PATH"
    fi

    BUILD_TESTS=${BUILD_TESTS:-false}
    angle_enable_d3d9=false
    angle_enable_d3d11=false
    angle_enable_gl=false
    angle_enable_metal=false
    angle_enable_null=false
    angle_enable_vulkan=false
    angle_enable_essl=true
    angle_enable_glsl=true
    angle_enable_cl=false
    is_clang=true

    is_component_build=false
    is_debug=false
    angle_assert_always_on=true   # Recommended for debugging. Turn off for performance.

    case "$TYPE" in
        vs)
            angle_enable_d3d11=true
            angle_enable_vulkan=true
            is_clang=false
            ;;
        osx)
            angle_enable_metal=true
            angle_enable_cl=true
            ;;
        ios)
            angle_enable_metal=true
            angle_enable_cl=true
            ;;
        tvos|xros|catos|watchos)
            angle_enable_metal=true
            ;;
        android|linux)
            angle_enable_gl=true
            angle_enable_vulkan=true
            ;;
        emscripten)
            angle_enable_gl=true
            ;;
        *)
            echo "Unsupported TYPE: $TYPE"
            exit 1
            ;;
    esac
    EXTRA_GN_ARGS=""
    case "$TYPE" in
        osx|ios|tvos)
            EXTRA_GN_ARGS="
                dcheck_always_on=true
                enable_run_ios_unittests_with_xctest=true
                is_component_build=${is_component_build}
                is_debug=${is_debug}
                angle_assert_always_on=${angle_assert_always_on}
                symbol_level=1"
            if [ ${ARCH_IS_SIMULATOR-:"false"} == "true" ]; then
                EXTRA_GN_ARGS="${EXTRA_GN_ARGS} target_environment=\"simulator\""
            fi
            ;;
        android)
            EXTRA_GN_ARGS="
                dcheck_always_on=true
                is_component_build=${is_component_build}
                is_debug=${is_debug}
                angle_assert_always_on=${angle_assert_always_on}
                symbol_level=1"
            ;;
    esac

    GN_ARGS="
        angle_enable_d3d9=${angle_enable_d3d9}
        angle_enable_d3d11=${angle_enable_d3d11}
        angle_enable_gl=${angle_enable_gl}
        angle_enable_metal=${angle_enable_metal}
        angle_enable_null=${angle_enable_null}
        angle_enable_vulkan=${angle_enable_vulkan}
        angle_enable_essl=${angle_enable_essl}
        angle_enable_glsl=${angle_enable_glsl}
        angle_enable_cl=${angle_enable_cl}
        angle_build_tests=${BUILD_TESTS}
        target_os=\"$TYPE\"
        target_cpu=\"${ARCH:-x64}\"
        ${EXTRA_GN_ARGS}
    "
    DEFINES="${GN_ARGS}"
    GN_ARGS=$(echo "$GN_ARGS" | tr -s '\n' ' ' | sed 's/  */ /g')
    GN_ARGS=$(echo "$GN_ARGS" | sed 's/\s\s*/ /g' | sed 's/\s*=\s*/=/g' | sed 's/\s*$//')
    echoInfo "GN Args: [${GN_ARGS}]"
    echoInfo "gn --version: [$(gn --version)]"
    echoInfo "ninja --version: [$(ninja --version)]"
    echoInfo "Generating GN build files in [build_${TYPE}_${ARCH}]"

    if [ "$TYPE" == "android" ]; then
        source $APOTHECARY_DIR/configure/android_configure.sh $ABI cmake

        mkdir -p "build_${TYPE}_${ABI}"
        cd "build_${TYPE}_${ABI}"
        rm -f CMakeCache.txt *.a *.o

        DEFINES="-DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_STANDARD=${C_STANDARD} \
            -DCMAKE_CXX_STANDARD=${CPP_STANDARD} \
            -DCMAKE_CXX_STANDARD_REQUIRED=ON \
            -DCMAKE_CXX_EXTENSIONS=OFF \
            -DBUILD_SHARED_LIBS=OFF"
        cmake .. ${DEFINES} \
            -DCMAKE_TOOLCHAIN_FILE=$APOTHECARY_DIR/toolchains/android.toolchain.cmake \
            -DPLATFORM=$PLATFORM \
            -DANDROID_ABI=${ABI} \
            -DANDROID_API=${ANDROID_API} \
            -DANDROID_TOOLCHAIN=clang \
            -DANDROID_NDK_ROOT=$ANDROID_NDK_ROOT \
            -DCMAKE_PREFIX_PATH="${LIBS_ROOT}" \
            -DCMAKE_INSTALL_PREFIX=Release \
            -DCMAKE_INCLUDE_OUTPUT_DIRECTORY=include \
            -DCMAKE_INSTALL_INCLUDEDIR=include \
            -DCMAKE_VERBOSE_MAKEFILE=ON \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_MINIMUM_REQUIRED_VERSION=3.22
        cmake --build . --config Release -j${PARALLEL_MAKE} --target install
        cd ..
    elif [[ "$TYPE" =~ ^(osx|ios|tvos|xros|catos|watchos)$ ]]; then
        mkdir -p "build_${TYPE}_${PLATFORM}"
        cd "build_${TYPE}_${PLATFORM}"
        rm -f CMakeCache.txt *.a *.o
        cmake .. \
            -DCMAKE_INSTALL_PREFIX=Release \
            -DCMAKE_VERBOSE_MAKEFILE=${VERBOSE_MAKEFILE} \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_PREFIX_PATH="${LIBS_ROOT}" \
            -DDEPLOYMENT_TARGET=${MIN_SDK_VER} \
            -DCMAKE_C_STANDARD=${C_STANDARD} \
            -DCMAKE_CXX_STANDARD=${CPP_STANDARD} \
            -DCMAKE_CXX_STANDARD_REQUIRED=ON \
            -DCMAKE_CXX_EXTENSIONS=OFF \
            -DCMAKE_TOOLCHAIN_FILE=$APOTHECARY_DIR/toolchains/ios.toolchain.cmake \
            -DPLATFORM=$PLATFORM \
            -DENABLE_BITCODE=OFF \
            -DENABLE_ARC=OFF \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_MINIMUM_REQUIRED_VERSION=3.22 \
            -DENABLE_VISIBILITY=OFF
        cmake --build . --config Release -j${PARALLEL_MAKE} --target install
        cd ..
    elif [ "$TYPE" == "emscripten" ]; then
        mkdir -p build_${TYPE}_${PLATFORM}
        cd build_${TYPE}_${PLATFORM}
        rm -f CMakeCache.txt *.a *.o *.js
        $EMSDK/upstream/emscripten/emcmake cmake .. \
            -DCMAKE_INSTALL_LIBDIR="lib" \
            -DCMAKE_TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake \
            -DLINK_FLAGS="${LINK_FLAGS}" \
            -DCMAKE_VERBOSE_MAKEFILE=${VERBOSE_MAKEFILE} \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_MINIMUM_REQUIRED_VERSION=3.22 \
            -DCMAKE_C_STANDARD=${C_STANDARD} \
            -DCMAKE_CXX_STANDARD=${CPP_STANDARD} \
            -DCMAKE_CXX_STANDARD_REQUIRED=ON \
            -DCMAKE_CXX_FLAGS=" ${FLAG_RELEASE}" \
            -DCMAKE_C_FLAGS="${FLAG_RELEASE}" \
            -DCMAKE_PREFIX_PATH="${LIBS_ROOT}" \
            -DCMAKE_CXX_EXTENSIONS=OFF \
            -DCMAKE_INSTALL_PREFIX=Release \
            -DCMAKE_INCLUDE_OUTPUT_DIRECTORY=include \
            -G 'Unix Makefiles'
        $EMSDK/upstream/emscripten/emmake make -j${PARALLEL_MAKE}
        $EMSDK/upstream/emscripten/emmake make install
        cd ..
    elif [ "$TYPE" == "vs" ]; then
        echoVerbose "Building ANGLE for vs | $ARCH | VS: $VS_VER_GEN"
        echoVerbose "--------------------"
        GENERATOR_NAME="Visual Studio ${VS_VER_GEN}"
        mkdir -p "build_${TYPE}_${ARCH}"
        cd "build_${TYPE}_${ARCH}"
        rm -f CMakeCache.txt *.lib *.o *.a

        cmake .. -G "${GENERATOR_NAME}" -A "${PLATFORM}" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_STANDARD=${C_STANDARD} \
            -DCMAKE_CXX_STANDARD=${CPP_STANDARD} \
            -DCMAKE_CXX_STANDARD_REQUIRED=ON \
            -DCMAKE_CXX_EXTENSIONS=OFF \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_INSTALL_PREFIX=Release \
            -DCMAKE_INCLUDE_OUTPUT_DIRECTORY=include \
            -DCMAKE_INSTALL_INCLUDEDIR=include \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCMAKE_MINIMUM_REQUIRED_VERSION=3.22 \
            -DANGLE_ENABLE_D3D11=ON \   # Enable Direct3D 11 backend (typical for Windows)
            -DANGLE_ENABLE_VULKAN=OFF \  # Disable Vulkan backend if not needed
            -DANGLE_ENABLE_GL=OFF         # Disable OpenGL backend, if desired
        cmake --build . --config Release -j${PARALLEL_MAKE} --target install
        cd ..
    else
        make install
    fi
   

    # if [ $TYPE == "vs" ]; then
    #     gn gen out/Debug --sln=angle-debug --ide=vs2022 --args='$GN_ARGS' out/Debug
    #     autoninja -C out/Debug
    # else
    #     gn gen --args='$GN_ARGS' out/Release
    #     ninja -j 10 -k1 -C out/Release
    # fi


    #ninja -C "out/Debug" -j${PARALLEL_MAKE}
    
}

function copy() {
    mkdir -p "$1/include"
    . "$SECURE_SCRIPT"
    if [ -d angle/include ]; then
        cp -Rv angle/include/* "$1/include/"
    else
        echo "Warning: angle/include not found!"
    fi
    mkdir -p "$1/lib/$TYPE/$PLATFORM/"
    if [ -f build_${TYPE}_${ARCH}/libEGL.a ]; then
        cp -v build_${TYPE}_${ARCH}/libEGL.a "$1/lib/$TYPE/$PLATFORM/libEGL.a"
    else
        echo "Warning: build_${TYPE}_${ARCH}/libEGL.a not found!"
    fi
    if [ -f build_${TYPE}_${ARCH}/libGLESv2.a ]; then
        cp -v build_${TYPE}_${ARCH}/libGLESv2.a "$1/lib/$TYPE/$PLATFORM/libGLESv2.a"
    else
        echo "Warning: build_${TYPE}_${ARCH}libGLESv2.a not found!"
    fi
    if [ -d "$1/license" ]; then
        rm -rf "$1/license"
    fi
    mkdir -p "$1/license"
    cp -v LICENSE "$1/license/"
}

# Clean the GN build output.
function clean() {
    if [ -d "build_${TYPE}_${ARCH}" ]; then
        echo "Removing existing build directory: build_${TYPE}_${ARCH}"
        rm -rf "build_${TYPE}_${ARCH}"
    fi
}
