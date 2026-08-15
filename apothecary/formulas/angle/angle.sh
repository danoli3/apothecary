#!/usr/bin/env bash
#
# ANGLE — GLES → D3D11 on Windows (OpenGL ES 2/3 + EGL)
# https://github.com/google/angle
#
# VS-only for now. Apple GLES→Metal is metalangle. Desktop GL→D3D12 is glon12.
# Official build is depot_tools + gn + ninja (not the stale unofficial CMake).
# target_os must be "win" (PR #533 passed TYPE=vs and that is wrong).
#
# Output: libEGL.dll + libGLESv2.dll. OF keeps ofGLProgrammableRenderer;
# the window must be EGL (GLFW EGL or ofAppEGLWindow) under OF_USE_ANGLE.

FORMULA_TYPES=("vs")
FORMULA_DEPENDS=()

VER=2026.08.13
SOURCE_COMMIT=7e8009eb2c42996fe6e7337bf8d12e1cfe4a1b80
BUILD_ID=1
DEFINES="angle_enable_d3d11=true angle_enable_vulkan=false"

GIT_URL=https://github.com/google/angle.git
GIT_URL_FALLBACK=https://chromium.googlesource.com/angle/angle
DEPOT_TOOLS_URL=https://chromium.googlesource.com/chromium/tools/depot_tools.git

function download() {
    . "$DOWNLOADER_SCRIPT"

    if [ -d angle ]; then
        rm -rf angle
    fi
    mkdir -p angle
    git -C angle init
    git -C angle remote add origin "${GIT_URL}" 2>/dev/null || git -C angle remote set-url origin "${GIT_URL}"
    if ! git -C angle fetch --depth=1 origin "${SOURCE_COMMIT}"; then
        echoWarning "github.com/google/angle fetch failed; trying ${GIT_URL_FALLBACK}"
        git -C angle remote set-url origin "${GIT_URL_FALLBACK}"
        git -C angle fetch --depth=1 origin "${SOURCE_COMMIT}"
    fi
    git -C angle checkout --force FETCH_HEAD
    verify_git_commit angle "${SOURCE_COMMIT}"
}

# Git for Windows git.exe — Win32 gclient/vpython cannot run MSYS /usr/bin/git.
function _angle_git_win_dir() {
    local d
    for d in \
        "/c/Program Files/Git/cmd" \
        "/c/Program Files/Git/bin" \
        "/c/Program Files (x86)/Git/cmd"
    do
        if [ -f "${d}/git.exe" ]; then
            echo "${d}"
            return 0
        fi
    done
    return 1
}

function _angle_depot_env() {
    local vendor="${1:-$(pwd)/.vendor}"
    export DEPOT_TOOLS_UPDATE=0
    export DEPOT_TOOLS_WIN_TOOLCHAIN=0
    mkdir -p "${vendor}/git_cache"
    if command -v cygpath >/dev/null 2>&1; then
        export GIT_CACHE_PATH="$(cygpath -w "${vendor}/git_cache")"
    else
        export GIT_CACHE_PATH="${vendor}/git_cache"
    fi
    local git_dir
    git_dir="$(_angle_git_win_dir || true)"
    export PATH="${vendor}/depot_tools${git_dir:+:${git_dir}}:${PATH}"
}

# gclient/gn/autoninja are Win32. cmd.exe PATH must be C:\... so git.bat is found.
function _angle_win_run() {
    local vendor dt_w winpath git_dir py_dir
    vendor="$(pwd)/.vendor"
    dt_w="$(cygpath -w "${vendor}/depot_tools")"
    winpath="${dt_w}"
    git_dir="$(_angle_git_win_dir || true)"
    if [ -n "${git_dir}" ]; then
        winpath="${winpath};$(cygpath -w "${git_dir}")"
    fi
    py_dir="$(dirname "$(command -v python 2>/dev/null || true)")"
    if [ -n "${py_dir}" ] && [[ "${py_dir}" != *WindowsApps* ]]; then
        winpath="${winpath};$(cygpath -w "${py_dir}")"
    fi
    echo "angle: cmd ${*}"
    cmd.exe //c "set PATH=${winpath};%PATH% && $*"
}

function prepare() {
    local vendor
    vendor="$(pwd)/.vendor"
    mkdir -p "${vendor}"
    if [ ! -d "${vendor}/depot_tools/.git" ]; then
        git clone --depth=1 "${DEPOT_TOOLS_URL}" "${vendor}/depot_tools"
    fi
    _angle_depot_env "${vendor}"

    if [ "$TYPE" = "vs" ]; then
        if ! _angle_git_win_dir >/dev/null; then
            echoError "angle: Git for Windows git.exe not found (MSYS git is not enough)."
            echoError "  winget install -e --id Git.Git"
            echoError "  Need: C:\\\\Program Files\\\\Git\\\\cmd\\\\git.exe"
            exit 1
        fi
        _angle_win_run "python scripts\\bootstrap.py"
        _angle_win_run "gclient sync --no-history --shallow"
    else
        python3 scripts/bootstrap.py
        gclient sync --no-history --shallow
    fi
}

function _angle_cpu() {
    case "${ARCH}" in
        32|x86) echo "x86" ;;
        arm64|arm64ec) echo "arm64" ;;
        *) echo "x64" ;;
    esac
}

function build() {
    if [ "$TYPE" != "vs" ]; then
        echoError "angle formula is VS-only here (Apple uses metalangle)"
        exit 1
    fi

    setup_vs_vars
    export VSINSTALLDIR="${VS_INSTALL_PATH:-${VS_BASE_PATH}}"
    _angle_depot_env "$(pwd)/.vendor"

    local cpu
    cpu="$(_angle_cpu)"
    local outdir="out/Release_${PLATFORM}"

    # is_clang=false → MSVC. D3D11 is the GLES backend. No Vulkan/GL/Metal.
    local gn_args
    gn_args="is_debug=false is_component_build=false is_clang=false symbol_level=0 angle_assert_always_on=false angle_build_tests=false angle_enable_d3d9=false angle_enable_d3d11=true angle_enable_d3d12=false angle_enable_gl=false angle_enable_metal=false angle_enable_null=false angle_enable_vulkan=false angle_enable_essl=true angle_enable_glsl=true target_os=\"win\" target_cpu=\"${cpu}\""
    DEFINES="${gn_args}"

    gn gen "${outdir}" --args="${gn_args}"
    autoninja -C "${outdir}" libEGL libGLESv2
}

function copy() {
    echo "copy angle -> $1"
    mkdir -p "$1/include" "$1/lib/$TYPE/$PLATFORM" "$1/bin/$TYPE/$PLATFORM"
    . "$SECURE_SCRIPT"

    if [ -d include ]; then
        cp -R include/. "$1/include/"
    else
        echoError "angle: include/ missing"
        exit 1
    fi

    local outdir="out/Release_${PLATFORM}"
    local copied=0
    local f
    for f in "${outdir}/libEGL.dll" "${outdir}/libGLESv2.dll"; do
        if [ -f "$f" ]; then
            cp -v "$f" "$1/bin/$TYPE/$PLATFORM/"
            copied=1
        fi
    done
    for f in "${outdir}/libEGL.dll.lib" "${outdir}/libGLESv2.dll.lib" \
        "${outdir}/libEGL.lib" "${outdir}/libGLESv2.lib"; do
        if [ -f "$f" ]; then
            cp -v "$f" "$1/lib/$TYPE/$PLATFORM/"
            copied=1
        fi
    done
    if [ -f "${outdir}/d3dcompiler_47.dll" ]; then
        cp -v "${outdir}/d3dcompiler_47.dll" "$1/bin/$TYPE/$PLATFORM/"
    fi

    if [ "$copied" -eq 0 ]; then
        echoError "angle: no libEGL/libGLESv2 under ${outdir}"
        ls -la "${outdir}" | head -40 || true
        exit 1
    fi

    if [ -f "$1/bin/$TYPE/$PLATFORM/libGLESv2.dll" ]; then
        secure "$1/bin/$TYPE/$PLATFORM/libGLESv2.dll" "angle.pkl" "$VERSION" "$DEFINES" "$BUILD_ID" "$FORMULA_DEPENDS"
    elif [ -f "$1/lib/$TYPE/$PLATFORM/libGLESv2.lib" ]; then
        secure "$1/lib/$TYPE/$PLATFORM/libGLESv2.lib" "angle.pkl" "$VERSION" "$DEFINES" "$BUILD_ID" "$FORMULA_DEPENDS"
    fi

    if [ -d "$1/license" ]; then
        rm -rf "$1/license"
    fi
    mkdir -p "$1/license"
    if [ -f LICENSE ]; then
        cp -v LICENSE "$1/license/"
    fi
}

function clean() {
    rm -rf "out/Release_${PLATFORM}"
}

function load() {
    . "$LOAD_SCRIPT"
    LOAD_RESULT=$(loadsave ${TYPE} "angle" ${ARCH} ${VER} "$LIBS_DIR_REAL/angle/bin/$TYPE/$PLATFORM" ${BUILD_ID})
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
