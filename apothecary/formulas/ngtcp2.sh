#!/usr/bin/env bash
#
# ngtcp2 - QUIC transport library with the OpenSSL 3.5+ crypto helper
# https://github.com/ngtcp2/ngtcp2

FORMULA_TYPES=("vs" "osx" "ios" "xros" "tvos" "catos" "watchos" "android")
FORMULA_DEPENDS=("openssl")

VER=1.25.0
SHA256="1c0843076528a87b65e9a9d455100941f4cb65d44f96c5da6ae56df146043955"
BUILD_ID=1
DEFINES="-DNGTCP2_STATICLIB"

GIT_URL=https://github.com/ngtcp2/ngtcp2
GIT_TAG=v$VER

function download() {
    . "$DOWNLOADER_SCRIPT"
    downloader "$GIT_URL/releases/download/v$VER/ngtcp2-$VER.tar.gz"
    verify_sha256 "ngtcp2-$VER.tar.gz" "$SHA256"
    tar -xf "ngtcp2-$VER.tar.gz"
    mv "ngtcp2-$VER" ngtcp2
    rm -f "ngtcp2-$VER.tar.gz"
}

function prepare() {
    :
}

function build() {
    local libs_root openssl_root build_dir
    libs_root=$(realpath "$LIBS_DIR")
    openssl_root="$libs_root/openssl"
    build_dir="build_${TYPE}_${PLATFORM}"
    local platform_args=()

    if [ "$TYPE" == "vs" ]; then
        unset PKG_CONFIG_PATH PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
        platform_args=(
            -G "Visual Studio ${VS_VER_GEN}"
            -A "$PLATFORM"
            ${CMAKE_WIN_SDK}
            -DOPENSSL_SSL_LIBRARY="$openssl_root/lib/$TYPE/$PLATFORM/libssl.lib"
            -DOPENSSL_CRYPTO_LIBRARY="$openssl_root/lib/$TYPE/$PLATFORM/libcrypto.lib"
        )
    elif [ "$TYPE" == "android" ]; then
        source "$APOTHECARY_DIR/configure/android_configure.sh" "$ABI" cmake
        platform_args=(
            -DCMAKE_TOOLCHAIN_FILE="$APOTHECARY_DIR/toolchains/android.toolchain.cmake"
            -DANDROID_ABI="$ABI"
            -DANDROID_API="$ANDROID_API"
            -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT"
            -DOPENSSL_SSL_LIBRARY="$openssl_root/lib/$TYPE/$PLATFORM/libssl.a"
            -DOPENSSL_CRYPTO_LIBRARY="$openssl_root/lib/$TYPE/$PLATFORM/libcrypto.a"
        )
    else
        platform_args=(
            -DCMAKE_TOOLCHAIN_FILE="$APOTHECARY_DIR/toolchains/ios.toolchain.cmake"
            -DPLATFORM="$PLATFORM"
            -DDEPLOYMENT_TARGET="$MIN_SDK_VER"
            -DENABLE_BITCODE=OFF
            -DOPENSSL_SSL_LIBRARY="$openssl_root/lib/$TYPE/$PLATFORM/libssl.a"
            -DOPENSSL_CRYPTO_LIBRARY="$openssl_root/lib/$TYPE/$PLATFORM/libcrypto.a"
        )
    fi

    rm -rf "$build_dir"
    cmake -S . -B "$build_dir" \
        "${platform_args[@]}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$build_dir/Release" \
        -DCMAKE_INSTALL_INCLUDEDIR=include \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DENABLE_STATIC_LIB=ON \
        -DENABLE_SHARED_LIB=OFF \
        -DENABLE_LIB_ONLY=ON \
        -DENABLE_OPENSSL=ON \
        -DENABLE_BORINGSSL=OFF \
        -DENABLE_GNUTLS=OFF \
        -DENABLE_PICOTLS=OFF \
        -DENABLE_WOLFSSL=OFF \
        -DENABLE_WERROR=OFF \
        -DBUILD_TESTING=OFF \
        -DOPENSSL_ROOT_DIR="$openssl_root" \
        -DOPENSSL_INCLUDE_DIR="$openssl_root/include"

    grep -q '^HAVE_SSL_SET_QUIC_TLS_CBS:INTERNAL=1$' "$build_dir/CMakeCache.txt" || {
        echo "ngtcp2 could not verify the OpenSSL QUIC API"
        exit 1
    }
    cmake --build "$build_dir" --config Release -j"${PARALLEL_MAKE}" --target install
}

function copy() {
    local build_dir="build_${TYPE}_${PLATFORM}/Release"
    local extension=a
    local transport_name=libngtcp2.a
    local crypto_name=libngtcp2_crypto_ossl.a
    if [ "$TYPE" == "vs" ]; then
        extension=lib
        transport_name=ngtcp2.lib
        crypto_name=ngtcp2_crypto_ossl.lib
    fi

    mkdir -p "$1/include" "$1/lib/$TYPE/$PLATFORM" "$1/license"
    cp -Rv "$build_dir/include/"* "$1/include/"
    cp -v "$build_dir/lib/$transport_name" "$1/lib/$TYPE/$PLATFORM/ngtcp2.$extension"
    cp -v "$build_dir/lib/$crypto_name" "$1/lib/$TYPE/$PLATFORM/ngtcp2_crypto_ossl.$extension"
    cp -v COPYING "$1/license/"

    . "$SECURE_SCRIPT"
    secure "$1/lib/$TYPE/$PLATFORM/ngtcp2.$extension" "ngtcp2.pkl" \
        "$VERSION" "$DEFINES" "$BUILD_ID" "${FORMULA_DEPENDS[*]}"
}

function clean() {
    local build_dir="build_${TYPE}_${PLATFORM}"
    [ -d "$build_dir" ] && rm -r "$build_dir"
}

function load() {
    . "$LOAD_SCRIPT"
    LOAD_RESULT=$(loadsave "$TYPE" "ngtcp2" "$ARCH" "$VER" \
        "$LIBS_DIR_REAL/$1/lib/$TYPE/$PLATFORM" "$BUILD_ID")
    PREBUILT=$(echo "$LOAD_RESULT" | tail -n 1)
    [ "$PREBUILT" -eq 1 ] && echo 1 || echo 0
}
