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
BUILD_ID=2
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

    . "$DOWNLOADER_SCRIPT"
    downloader "https://github.com/lexxmark/winflexbison/releases/download/v${WINFLEX_VER}/win_flex_bison-${WINFLEX_VER}.zip"
    verify_sha256 "win_flex_bison-${WINFLEX_VER}.zip" "$WINFLEX_SHA256"
    mkdir -p winflexbison
    unzip -q "win_flex_bison-${WINFLEX_VER}.zip" -d winflexbison
    rm -f "win_flex_bison-${WINFLEX_VER}.zip"
    export PATH="$(pwd)/winflexbison:${PATH}"
}

# vcvarsall arch: meson needs INCLUDE/LIB, not just cl.exe on PATH.
function _glon12_vcvars_arch() {
    case "$ARCH" in
        32 | x86) echo "x86" ;;
        arm64 | ARM64)
            case "${PROCESSOR_ARCHITECTURE:-${HOSTTYPE:-}}" in
                ARM64 | aarch64 | arm64) echo "arm64" ;;
                *) echo "amd64_arm64" ;;
            esac
            ;;
        arm64ec) echo "amd64_arm64" ;;
        *) echo "x64" ;;
    esac
}

# executed inside the lib src dir
function build() {
    if [ "$TYPE" != "vs" ]; then
        echoError "glon12 is VS-only"
        exit 1
    fi

    setup_vs_vars
    export VSINSTALLDIR="${VS_INSTALL_PATH:-${VS_BASE_PATH}}"
    export PATH="$(pwd)/winflexbison:${PATH}"

    local bdir="build_${TYPE}_${PLATFORM}"
    rm -rf "${bdir}"
    mkdir -p "${bdir}"

    local meson_backend="ninja"
    if ! command -v ninja >/dev/null 2>&1; then
        meson_backend="vs"
    fi

    local vsroot vcvars
    vsroot="${VS_INSTALL_PATH:-$VS_BASE_PATH}"
    vsroot="$(cygpath -u "$vsroot" 2>/dev/null || echo "$vsroot")"
    vcvars="$(cygpath -wa "${vsroot}/VC/Auxiliary/Build/vcvarsall.bat")"
    local varch
    varch="$(_glon12_vcvars_arch)"
    local src_win bdir_win flex_win meson_win ninja_win prefix_win
    src_win="$(cygpath -wa "$(pwd)")"
    bdir_win="$(cygpath -wa "$(pwd)/${bdir}")"
    flex_win="$(cygpath -wa "$(pwd)/winflexbison")"
    meson_win="$(cygpath -wa "$(command -v meson)")"
    ninja_win="$(cygpath -wa "$(command -v ninja)")"
    prefix_win="$(cygpath -wa "$(pwd)/${bdir}/Release")"

    echo "glon12: vcvarsall=${vcvars} arch=${varch}"
    echo "glon12: meson=${meson_win} ninja=${ninja_win}"

    local bat="glon12_vs_build.bat"
    cat >"$bat" <<EOF
@echo off
setlocal
echo glon12 bat: calling vcvarsall ${varch}
call "${vcvars}" ${varch}
if errorlevel 1 (
  echo vcvarsall ${varch} failed, trying arm64
  call "${vcvars}" arm64
)
if errorlevel 1 (
  echo vcvarsall arm64 failed, trying amd64_arm64
  call "${vcvars}" amd64_arm64
)
if errorlevel 1 (
  echo vcvarsall amd64_arm64 failed, trying x64
  call "${vcvars}" x64
)
echo INCLUDE=%INCLUDE%
where cl
set "PATH=${flex_win};%PATH%"
cd /d "${src_win}"
"${meson_win}" setup "${bdir_win}" --backend=${meson_backend} --buildtype=release --prefix="${prefix_win}" -Dgallium-drivers=d3d12 -Dgallium-d3d12-video=disabled -Dzlib=disabled -Dllvm=disabled -Dplatforms=windows -Dbuild-tests=false
if errorlevel 1 exit /b 1
if "${meson_backend}"=="ninja" (
  "${ninja_win}" -C "${bdir_win}" -j ${PARALLEL_MAKE:-8}
  if errorlevel 1 exit /b 1
  "${ninja_win}" -C "${bdir_win}" install
) else (
  msbuild "${bdir_win}\\mesa.sln" /m /p:Configuration=Release /p:Platform=${PLATFORM}
  if errorlevel 1 exit /b 1
  "${meson_win}" install -C "${bdir_win}"
)
EOF

    cmd.exe //c "$(cygpath -wa "$bat")"
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
