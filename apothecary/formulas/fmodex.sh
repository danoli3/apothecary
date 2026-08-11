#!/usr/bin/env bash
#
# FmodEX
# http://www.portaudio.com/
#
# This is not a build script, as fmodex is linked as a dynamic library.
# FmodEX is downloaded as a binary from the fmod.org website and copied
# into the openFrameworks library directory.

FORMULA_TYPES=("msys2" "osx" "vs" "linux" "linux64")
FORMULA_DEPENDS=()

# define the version
VER=44459
SHA256_OSX=48cb36127da987dc00a60f081edca67d1440518f40cf4bf7c4b4639f2776eca9
SHA256_LINUX=9edd7f017e68c2152c215a71c224a6dfc0c2b05d1388586bd11243273d967bac
SHA256_LINUX64=8919d6afdbb924bf1b811d11c6a1b8e955cb8930fe48ec6905dccb40d6981b65
SHA256_VS32=9f35f2f9a19fe8670411a1e81a1cd84401bb1af5bafce71d1e8cff0d35c6aa43
SHA256_VS64=abd10acbf1924c75d4a198b2bbfd3a4b2afde49d2ef1feb9de506149f5737d26
BUILD_ID=1
DEFINES=""

# tools for git use
GIT_URL=
GIT_TAG=
URL=http://openframeworks.cc/ci/fmodex/

# download the source code and unpack it into LIB_NAME
function download() {
    #Nothing to do for mingw64
    if [ "$TYPE" == "msys2" ] && [ "$ARCH" == "64" ]; then
        mkdir fmodex
        return
    fi
    if [ "$ARCH" == "arm64" ] || [ "$ARCH" == "arm64ec" ] || [ "$ARCH" == "arm" ]; then
        PKG=fmodex_${TYPE}${ARCH}.tar.bz2
        mkdir fmodex
        return 0

    else
        PKG=fmodex_${TYPE}.tar.bz2
    fi
    . "$DOWNLOADER_SCRIPT"
    downloader "${URL}/${PKG}"
    case "$TYPE:$ARCH" in
        osx:*) expected_sha="$SHA256_OSX" ;;
        linux:*) expected_sha="$SHA256_LINUX" ;;
        linux64:*) expected_sha="$SHA256_LINUX64" ;;
        vs:32) expected_sha="$SHA256_VS32" ;;
        vs:64) expected_sha="$SHA256_VS64" ;;
        *) echoError "No SHA-256 is recorded for $PKG"; return 1 ;;
    esac
    verify_sha256 "$PKG" "$expected_sha"
    tar xjf $PKG
    rm "${PKG}"
}

# prepare the build environment, executed inside the lib src dir
function prepare() {
    : # noop
    # mount install
}

# executed inside the lib src dir
function build() {

    if [ "$ARCH" == "arm64" ] || [ "$ARCH" == "arm64ec" ] || [ "$ARCH" == "arm" ]; then
        if [ "$ARCH" == "arm64" ] || [ "$ARCH" == "arm64ec" ]; then
            return 0
        fi
    fi

    if [ "$TYPE" == "osx" ]; then
        cd lib/osx
        install_name_tool -id "@executable_path/libfmodex.dylib" libfmodex.dylib
        cd ../
    fi

}

# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {
    cp -r ../fmodex/ $1/
}

# executed inside the lib src dir
function clean() {
    : # noop
}
