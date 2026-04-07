#!/usr/bin/env bash
#
# GLon12 - Mesa Gallium D3D12 OpenGL → DX12 driver
# (Meson is now manually installed – no more msiexec popup)
# For ofxTaxSoftware – native Poppler PDF parser + ImGui tables

FORMULA_TYPES=("vs")
FORMULA_DEPENDS=()

VER=26.0.4
BUILD_ID=9
DEFINES=""

function download() {
    . "$DOWNLOADER_SCRIPT"
    downloader "https://archive.mesa3d.org/mesa-${VER}.tar.xz"
    tar -xf "mesa-${VER}.tar.xz"
    mv "mesa-${VER}" glon12
    rm "mesa-${VER}.tar.xz"
    echo "Downloaded GLon12 (Mesa ${VER})"
}

function prepare() {
    # Auto-detect standard Meson MSI install location
    if [ -d "/c/Program Files/Meson" ]; then
        export PATH="/c/Program Files/Meson:$PATH"
        echo "✅ Added Meson to PATH: /c/Program Files/Meson"
    fi
    if command -v meson >/dev/null 2>&1 && command -v ninja >/dev/null 2>&1; then
        echo "✅ Meson + Ninja found"
        meson --version
        ninja --version
    else
        echo "❌ Meson still not found."
        echo " Make sure you installed the -64.msi from https://github.com/mesonbuild/meson/releases/latest"
        echo " (Install for all users)"
        exit 1
    fi

    # === WinFlexBison from GitHub latest release (official Mesa recommendation) ===
    echo "✅ Setting up WinFlexBison (GitHub lexxmark/winflexbison v2.5.25)..."
    . "$DOWNLOADER_SCRIPT"
    downloader "https://github.com/lexxmark/winflexbison/releases/download/v2.5.25/win_flex_bison-2.5.25.zip" "win_flex_bison-2.5.25.zip"
    mkdir -p winflexbison
    unzip -q "win_flex_bison-2.5.25.zip" -d winflexbison
    rm "win_flex_bison-2.5.25.zip"
    export PATH="$(pwd)/winflexbison:$PATH"
    echo "✅ Added WinFlexBison to PATH: $(pwd)/winflexbison"

}

function build() {
    if [ "$TYPE" == "vs" ]; then
        echo "building glon12 $TYPE | $PLATFORM | $ARCH | ofxTaxSoftware PDF parser + ImGui"

        # === apothecary VS setup + fix real VS2022 path ===
        setup_vs_vars
        export VS_BASE_PATH=$(echo "$VS_BIN_PATH" | sed 's|/VC/Tools/.*||' | sed 's|^/c/|C:/|')
        echo "✅ Fixed VS_BASE_PATH (real 2022 path) → $VS_BASE_PATH"

        # === Create build folder and generate the official VS Developer Prompt .bat ===
        mkdir -p "build_${PLATFORM}"
        cd "build_${PLATFORM}"   # ← move into the folder first (fixes relative path issues)

        local TEMP_BAT="mesa_vs_dev_prompt.bat"

        cat > "$TEMP_BAT" << EOF
@echo off
echo ====================================================
echo  GLon12 build inside official VS Developer Command Prompt
echo ====================================================
call "%VS_BASE_PATH%\VC\Auxiliary\Build\vcvars64.bat"
echo VS environment loaded (cl.exe + MSVCRT.lib + WinFlexBison ready)

meson setup .. ^
    --backend=vs2022 ^
    -Dgallium-drivers=d3d12 ^
    -Dgallium-d3d12-video=disabled ^
    -Dzlib=disabled ^
    -Dllvm=disabled ^
    -Dbuildtype=release ^
    -Dplatforms=windows

echo.
echo 🚀 Starting MSBuild (official Mesa way for ofxTaxSoftware Windows target)...
msbuild mesa.sln /m /p:Configuration=Release /p:Platform=${PLATFORM}
if %ERRORLEVEL% neq 0 (
    echo ❌ MSBuild failed – open mesa.sln in Visual Studio and build ALL_BUILD
    pause
    exit /b 1
)
echo ✅ GLon12 built successfully
EOF

        echo "✅ Generated official VS Developer Prompt .bat"

        # === Run it with proper Windows path ===
        cmd //c "$TEMP_BAT" || {
            echo "❌ Build failed"
            exit 1
        }

        cd ../..
    fi
}

function copy() {
    mkdir -p $1/bin/$TYPE/$PLATFORM
    . "$SECURE_SCRIPT"

    local BUILD_DIR="glon12/build_${PLATFORM}/src/gallium/targets"
    cp -v "${BUILD_DIR}/libgl-gdi/Release/opengl32.dll" "$1/bin/$TYPE/$PLATFORM/" 2>/dev/null || true
    cp -v "${BUILD_DIR}/wgl/Release/libgallium_wgl.dll" "$1/bin/$TYPE/$PLATFORM/" 2>/dev/null || true

    secure "$1/bin/$TYPE/$PLATFORM/opengl32.dll" "glon12.pkl" "$VERSION" "$DEFINES" "$BUILD_ID" "$FORMULA_DEPENDS" 2>/dev/null || true
    secure "$1/bin/$TYPE/$PLATFORM/libgallium_wgl.dll" "glon12.pkl" "$VERSION" "$DEFINES" "$BUILD_ID" "$FORMULA_DEPENDS" 2>/dev/null || true

    mkdir -p $1/license
    cp -v glon12/COPYING* $1/license/ 2>/dev/null || true
    echo "GLon12 (${PLATFORM}) copied"
}

function clean() { rm -rf glon12 build_* 2>/dev/null || true; }

function load() {
    . "$LOAD_SCRIPT"
    LOAD_RESULT=$(loadsave ${TYPE} "glon12" ${ARCH} ${VER} "$LIBS_DIR_REAL/$1/bin/$TYPE/$PLATFORM" ${BUILD_ID})
    PREBUILT=$(echo "$LOAD_RESULT" | tail -n 1)
    if [ "$PREBUILT" -eq 1 ]; then echo 1; else echo 0; fi
}