#!/usr/bin/env bash
#
# fmod
# https://www.fmod.com
#
# This is not a build script, as fmod is linked as a dynamic library.
# fmod is downloaded as a binary from the fmod.com website and copied
# into the openFrameworks library directory.

FORMULA_TYPES=()
LEGACY_FORMULA_TYPES=("osx" "vs" "linux" "linux64")
FORMULA_DEPENDS=()

# define the version
VER=44459
SHA256_OSX=66afb3146c436ba0d22651fd4b56f531afbf3abca446559bc3f0a198c7d0faa7
SHA256_LINUX=de59499c644f309b702bbf12795049c87f276e861b4e8fa880acebf4810a8ca8
SHA256_LINUX64=f4082ff99df3da9d5a1198295d3328b624f909fc9863783cda608643e5ac8fb3
SHA256_VS32=8a84e09057caac0a1bb6a4aa9b6282dc99c717dc2bcea871736de9c3b9084a62
SHA256_VS64=bdd3c5ac32df2b6decbcd4ddc5536ee2195f03db9a654e10df4e113548b35c8c
BUILD_ID=1
DEFINES=""

# tools for git use
GIT_URL=
GIT_TAG=

URL=http://openframeworks.cc/ci/fmod

# download the source code and unpack it into LIB_NAME
function download() {

    if [ "$TYPE" == "vs" ]; then
        PKG=fmod_${TYPE}${ARCH}.tar.bz2
        if [ "$ARCH" == "arm64" ] || [ "$ARCH" == "arm64ec" ] || [ "$ARCH" == "arm" ]; then
            mkdir fmod
            return 0
        fi
    else
        PKG=fmod_${TYPE}.tar.bz2
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
        return 0
    fi

    if [ "$TYPE" == "osx" ]; then
        cd lib/osx
        install_name_tool -id @executable_path/../Frameworks/libfmod.dylib libfmod.dylib
        cd ../
    fi

}

# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {
    cp -r ../fmod/ $1/

    if [ "$TYPE" == "osx" ]; then
        . "$SECURE_SCRIPT"
        secure $1/lib/$TYPE/libfmod.dylib fmod
    fi
}

# executed inside the lib src dir
function clean() {
    : # noop
}

function load() {
    . "$LOAD_SCRIPT"
    LOAD_RESULT=$(loadsave ${TYPE} "fmod" ${ARCH} ${VER} "$LIBS_DIR_REAL/$1/lib/$TYPE" ${PLATFORM})
    PREBUILT=$(echo "$LOAD_RESULT" | tail -n 1)
    if [ "$PREBUILT" -eq 1 ]; then
        echo 1
    else
        echo 0
    fi
}
