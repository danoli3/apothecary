#!/usr/bin/env bash
#
# nghttp2 - HTTP/2 C library
# https://github.com/nghttp2/nghttp2

FORMULA_TYPES=("vs")
FORMULA_DEPENDS=()

VER=1.70.0
SHA256="aa317e2cf9dca6afa0aed68f8fad6ff303ec6982e25a78c75c0b65e2b9b3ded5"
BUILD_ID=1
DEFINES="-DNGHTTP2_STATICLIB"

GIT_URL=https://github.com/nghttp2/nghttp2
GIT_TAG=v$VER

function download() {
    . "$DOWNLOADER_SCRIPT"
    downloader "$GIT_URL/releases/download/v$VER/nghttp2-$VER.tar.gz"
    verify_sha256 "nghttp2-$VER.tar.gz" "$SHA256"
    tar -xf "nghttp2-$VER.tar.gz"
    mv "nghttp2-$VER" nghttp2
    rm -f "nghttp2-$VER.tar.gz"
}

function prepare() {
    : # noop
}

function build() {
    local generator_name="Visual Studio ${VS_VER_GEN}"

    mkdir -p "build_${TYPE}_${ARCH}"
    cd "build_${TYPE}_${ARCH}"
    rm -f CMakeCache.txt *.lib *.o

    cmake .. \
        -G "$generator_name" \
        -A "$PLATFORM" \
        ${CMAKE_WIN_SDK} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=Release \
        -DCMAKE_INSTALL_INCLUDEDIR=include \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_C_STANDARD=${C_STANDARD} \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_STATIC_LIBS=ON \
        -DBUILD_TESTING=OFF \
        -DENABLE_APP=OFF \
        -DENABLE_DOC=OFF \
        -DENABLE_EXAMPLES=OFF \
        -DENABLE_HPACK_TOOLS=OFF \
        -DENABLE_LIB_ONLY=ON \
        -DENABLE_WERROR=OFF

    cmake --build . --config Release -j${PARALLEL_MAKE} --target install
    cd ..
}

function copy() {
    mkdir -p "$1/include" "$1/lib/$TYPE/$PLATFORM"
    cp -Rv "build_${TYPE}_${ARCH}/Release/include/"* "$1/include/"
    cp -v "build_${TYPE}_${ARCH}/Release/lib/nghttp2.lib" \
        "$1/lib/$TYPE/$PLATFORM/nghttp2.lib"

    . "$SECURE_SCRIPT"
    secure "$1/lib/$TYPE/$PLATFORM/nghttp2.lib" "nghttp2.pkl" \
        "$VERSION" "$DEFINES" "$BUILD_ID" "$FORMULA_DEPENDS"

    rm -rf "$1/license"
    mkdir -p "$1/license"
    cp -v COPYING "$1/license/"
}

function clean() {
    if [ -d "build_${TYPE}_${ARCH}" ]; then
        rm -r "build_${TYPE}_${ARCH}"
    fi
}

function load() {
    . "$LOAD_SCRIPT"
    LOAD_RESULT=$(loadsave "$TYPE" "nghttp2" "$ARCH" "$VER" \
        "$LIBS_DIR_REAL/$1/lib/$TYPE/$PLATFORM" "$BUILD_ID")
    PREBUILT=$(echo "$LOAD_RESULT" | tail -n 1)
    if [ "$PREBUILT" -eq 1 ]; then
        echo 1
    else
        echo 0
    fi
}
