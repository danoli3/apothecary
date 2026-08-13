#!/usr/bin/env bash
#
# GLon12 — Mesa Gallium OpenGL → D3D12 (Microsoft OpenGLOn12)
# https://docs.mesa3d.org/drivers/d3d12.html
#
# Brought forward from origin/openGLonDX12 @ 44174899.
# VS-only. Ships opengl32.dll + libgallium_wgl.dll next to the OF .exe so
# GLFW/GLEW keep working; the system OpenGL ICD is not used.
#
# Host needs: meson, ninja (or Meson VS backend + MSBuild), WinFlexBison
# (formula downloads the latter). Windows 10+ D3D12 runtime.

FORMULA_TYPES=("vs")
FORMULA_DEPENDS=()

VER=26.0.4
SHA256=6d91541e086f29bb003602d2c81070f2be4c0693a90b181ca91e46fa3953fe78
WINFLEX_VER=2.5.25
WINFLEX_SHA256=8d324b62be33604b2c45ad1dd34ab93d722534448f55a16ca7292de32b6ac135
BUILD_ID=4
DEFINES="-Dgallium-drivers=d3d12 -Dllvm=disabled -Dplatforms=windows"

GIT_URL=https://gitlab.freedesktop.org/mesa/mesa

# download the source code and unpack it into LIB_NAME
function download() {
    . "$DOWNLOADER_SCRIPT"
    downloader "https://archive.mesa3d.org/mesa-${VER}.tar.xz"
    verify_sha256 "mesa-${VER}.tar.xz" "$SHA256"
    tar -xf "mesa-${VER}.tar.xz"
    mv "mesa-${VER}" glon12
    rm "mesa-${VER}.tar.xz"
}

function prepare() {
    if [ -d "/c/Program Files/Meson" ]; then
        export PATH="/c/Program Files/Meson:$PATH"
    fi
    if ! command -v meson >/dev/null 2>&1; then
        echoError "glon12: meson not on PATH (install meson + ninja, or the Meson MSI)"
        exit 1
    fi

    # Mesa 26: Python 3.12 dropped distutils. meson.build requires packaging or distutils.
    local py
    py=""
    if command -v python >/dev/null 2>&1; then
        py="$(command -v python)"
    elif command -v python3 >/dev/null 2>&1; then
        py="$(command -v python3)"
    fi
    if [ -n "$py" ]; then
        if ! "$py" -c "import packaging" >/dev/null 2>&1 && ! "$py" -c "import distutils" >/dev/null 2>&1; then
            echo "glon12: installing Python packaging/mako (Mesa meson)"
            "$py" -m pip install --upgrade packaging mako pyyaml setuptools || true
        fi
        if ! "$py" -c "import packaging" >/dev/null 2>&1 && ! "$py" -c "import distutils" >/dev/null 2>&1; then
            echoError "glon12: Python packaging module missing. Run: \"$py\" -m pip install packaging mako"
            exit 1
        fi
    fi

    . "$DOWNLOADER_SCRIPT"
    downloader "https://github.com/lexxmark/winflexbison/releases/download/v${WINFLEX_VER}/win_flex_bison-${WINFLEX_VER}.zip"
    verify_sha256 "win_flex_bison-${WINFLEX_VER}.zip" "$WINFLEX_SHA256"
    mkdir -p winflexbison
    unzip -q "win_flex_bison-${WINFLEX_VER}.zip" -d winflexbison
    rm -f "win_flex_bison-${WINFLEX_VER}.zip"
    export PATH="$(pwd)/winflexbison:${PATH}"
}

# Mesa 26 has no CMake/SCons. Meson is required. Run it from bash (MSYS
# meson is a Python script — cmd.exe cannot launch it). Do not use a .bat.
function build() {
    if [ "$TYPE" != "vs" ]; then
        echoError "glon12 is VS-only"
        exit 1
    fi

    setup_vs_vars
    export VSINSTALLDIR="${VS_INSTALL_PATH:-${VS_BASE_PATH}}"

    local bdir="build_${TYPE}_${PLATFORM}"
    rm -rf "${bdir}"
    mkdir -p "${bdir}"

    local lib_arch msvc_root kits kitver
    lib_arch="$(basename "${VS_BIN_PATH}")"
    msvc_root="$(cd "${VS_BIN_PATH}/../../.." && pwd)"
    kits="/c/Program Files (x86)/Windows Kits/10"
    kitver="$(ls -1 "${kits}/Lib" 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1)"

    local inc_w lib_w
    inc_w="$(cygpath -w "${msvc_root}/include")"
    lib_w="$(cygpath -w "${msvc_root}/lib/${lib_arch}")"
    if [ -n "${kitver}" ]; then
        inc_w="${inc_w};$(cygpath -w "${kits}/Include/${kitver}/ucrt");$(cygpath -w "${kits}/Include/${kitver}/um");$(cygpath -w "${kits}/Include/${kitver}/shared")"
        lib_w="${lib_w};$(cygpath -w "${kits}/Lib/${kitver}/ucrt/${lib_arch}");$(cygpath -w "${kits}/Lib/${kitver}/um/${lib_arch}")"
    fi
    export INCLUDE="${inc_w}${INCLUDE:+;${INCLUDE}}"
    export LIB="${lib_w}${LIB:+;${LIB}}"
    export LIBPATH="${lib_w}${LIBPATH:+;${LIBPATH}}"

    # MSVC cl/link before Git/MSYS /usr/bin/link.exe
    export PATH="${VS_BIN_PATH}:$(pwd)/winflexbison:${PATH}"
    export CC="${VS_BIN_PATH}/cl.exe"
    export CXX="${VS_BIN_PATH}/cl.exe"
    export LD="${VS_BIN_PATH}/link.exe"

    echo "glon12: CC=${CC}"
    echo "glon12: LIB=${LIB}"
    if [ ! -f "${msvc_root}/lib/${lib_arch}/msvcrt.lib" ]; then
        echoError "glon12: missing ${msvc_root}/lib/${lib_arch}/msvcrt.lib"
        exit 1
    fi

    local meson_args=(
        setup "${bdir}"
        --backend=ninja
        --buildtype=release
        --prefix="$(pwd)/${bdir}/Release"
        -Dgallium-drivers=d3d12
        -Dgallium-d3d12-video=disabled
        -Dzlib=disabled
        -Dllvm=disabled
        -Dplatforms=windows
        -Dbuild-tests=false
    )
    # --vsenv is nice on a working VS; CI MSYS meson + our INCLUDE/LIB is enough.
    if ! meson "${meson_args[@]}" --vsenv; then
        echoWarning "glon12: meson --vsenv failed, retrying with INCLUDE/LIB only"
        rm -rf "${bdir}"
        mkdir -p "${bdir}"
        meson "${meson_args[@]}"
    fi
    meson compile -C "${bdir}" -j "${PARALLEL_MAKE}"
    meson install -C "${bdir}"
}

function copy() {
    echo "copy glon12 -> $1"
    mkdir -p "$1/include" "$1/bin/$TYPE/$PLATFORM" "$1/lib/$TYPE/$PLATFORM"
    . "$SECURE_SCRIPT"

    local bdir="build_${TYPE}_${PLATFORM}"
    local copied=0
    local f
    while IFS= read -r f; do
        cp -v "$f" "$1/bin/$TYPE/$PLATFORM/"
        copied=1
    done < <(find "${bdir}" -type f \( -iname 'opengl32.dll' -o -iname 'libgallium_wgl.dll' -o -iname 'libglapi.dll' \) 2>/dev/null)

    if [ "$copied" -eq 0 ]; then
        echoError "glon12: no opengl32.dll / libgallium_wgl.dll under ${bdir}"
        find "${bdir}" -iname '*.dll' | head -40 || true
        exit 1
    fi

    if [ -f "$1/bin/$TYPE/$PLATFORM/opengl32.dll" ]; then
        secure "$1/bin/$TYPE/$PLATFORM/opengl32.dll" "glon12.pkl" "$VERSION" "$DEFINES" "$BUILD_ID" "$FORMULA_DEPENDS"
    fi

    if [ -d "$1/license" ]; then
        rm -rf "$1/license"
    fi
    mkdir -p "$1/license"
    if [ -f docs/license.rst ]; then
        cp -v docs/license.rst "$1/license/"
    elif [ -f LICENSE ]; then
        cp -v LICENSE "$1/license/"
    fi
}

function clean() {
    rm -rf "build_${TYPE}_${PLATFORM}"
}

function load() {
    . "$LOAD_SCRIPT"
    LOAD_RESULT=$(loadsave ${TYPE} "glon12" ${ARCH} ${VER} "$LIBS_DIR_REAL/glon12/bin/$TYPE/$PLATFORM" ${BUILD_ID})
    PREBUILT=$(echo "$LOAD_RESULT" | tail -n 1)
    if [ "$PREBUILT" -eq 1 ]; then
        echo 1
    else
        TARGET_DIR="$LIBS_DIR_REAL/$1/bin/$TYPE/$PLATFORM"
        if [ -d "$TARGET_DIR" ]; then
            echoInfo "Deleting existing folder: $TARGET_DIR"
            rm -rf "$TARGET_DIR"
        fi
        echo 0
    fi
}
