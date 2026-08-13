#!/usr/bin/env bash
set -e

# trap any script errors and exit
trap "trapError" ERR

trapError() {
    echo
    echo " ^ Received error ^"
    exit 1
}

isRunning() {
    if [ “$(uname)” == “Linux” ]; then
        if [ -d /proc/$1 ]; then
            return 0
        else
            return 1
        fi
    else
        number=$(ps aux | sed -E "s/[^ ]* +([^ ]*).*/\1/g" | grep ^$1$ | wc -l)

        if [ $number -gt 0 ]; then
            return 0
        else
            return 1
        fi
    fi
}

echoDots() {
    while isRunning $1; do
        for i in $(seq 1 10); do
            echo -ne .
            if ! isRunning $1; then
                printf "\r"
                return
            fi
            sleep 2
        done
        printf "\r                    "
        printf "\r"
    done
}

# Git Bash: LOCALAPPDATA/APPDATA are often C:\Users\... (backslash). cygpath that.
WIN_USER="${USERNAME:-${USER:-}}"
WIN_LOCAL="${LOCALAPPDATA:-${HOME}/AppData/Local}"
WIN_ROAM="${APPDATA:-${HOME}/AppData/Roaming}"
if command -v cygpath >/dev/null 2>&1; then
    WIN_LOCAL="$(cygpath -u "$WIN_LOCAL" 2>/dev/null || echo "$WIN_LOCAL")"
    WIN_ROAM="$(cygpath -u "$WIN_ROAM" 2>/dev/null || echo "$WIN_ROAM")"
fi
WIN_LOCAL="${WIN_LOCAL//\\//}"
WIN_ROAM="${WIN_ROAM//\\//}"
# Official installer + pip --user (x64 and ARM64). User-site Scripts is not on PATH by default.
export PATH="$WIN_ROAM/Python/Python312-arm64/Scripts:$WIN_ROAM/Python/Python312/Scripts:$WIN_ROAM/Python/Python313-arm64/Scripts:$WIN_ROAM/Python/Python313/Scripts:$WIN_LOCAL/Programs/Python/Python312-arm64:$WIN_LOCAL/Programs/Python/Python312-arm64/Scripts:$WIN_LOCAL/Programs/Python/Python312:$WIN_LOCAL/Programs/Python/Python312/Scripts:$WIN_LOCAL/Programs/Python/Python313-arm64:$WIN_LOCAL/Programs/Python/Python313-arm64/Scripts:$WIN_LOCAL/Programs/Python/Python313:$WIN_LOCAL/Programs/Python/Python313/Scripts:/c/Users/${WIN_USER}/AppData/Local/Programs/Python/Python312:/c/Users/${WIN_USER}/AppData/Local/Programs/Python/Python312/Scripts:/c/Program Files/Python312:/c/Program Files/Python312/Scripts:/c/Program Files/Meson:/c/Program Files/Ninja:$PATH"

# winget: already-installed is ok. Missing package id is not.
winget_ensure() {
    local id="$1"
    if winget list -e --id "$id" >/dev/null 2>&1; then
        echo "winget: $id already installed"
        return 0
    fi
    if winget install -e --id "$id" --accept-package-agreements --accept-source-agreements; then
        return 0
    fi
    echo "winget: $id not installed (id may be wrong or already present)"
    return 0
}

if command -v winget >/dev/null 2>&1; then
    winget_ensure Microsoft.WindowsTerminal
    winget_ensure Ninja-build.Ninja
    winget_ensure mesonbuild.meson
    winget_ensure charmbracelet.Gum
    winget_ensure jqlang.jq
    winget_ensure Kitware.CMake
    winget_ensure Oracle.JDK.17
    winget_ensure Python.Python.3.12
fi

# MSYS2 / Git-Bash-with-pacman (same packages CI uses for GLon12)
if command -v pacman >/dev/null 2>&1; then
    pacman -S --noconfirm --needed \
        meson \
        mingw-w64-x86_64-ninja \
        mingw-w64-x86_64-gum \
        unzip \
        python3 || true
fi

# Real interpreter only. WindowsApps\python.exe is a Store stub.
python_ok() {
    local bin="$1"
    [ -n "$bin" ] && [ -x "$bin" ] || [ -f "$bin" ] || return 1
    "$bin" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >/dev/null 2>&1
}

find_python() {
    local cand
    shopt -s nullglob
    for cand in \
        "$WIN_LOCAL/Programs/Python/Python312-arm64/python.exe" \
        "$WIN_LOCAL/Programs/Python/Python312/python.exe" \
        "$WIN_LOCAL/Programs/Python/Python313-arm64/python.exe" \
        "$WIN_LOCAL/Programs/Python/Python313/python.exe" \
        "$HOME/AppData/Local/Programs/Python/Python312-arm64/python.exe" \
        "$HOME/AppData/Local/Programs/Python/Python312/python.exe" \
        "/c/Users/${WIN_USER}/AppData/Local/Programs/Python/Python312-arm64/python.exe" \
        "/c/Users/${WIN_USER}/AppData/Local/Programs/Python/Python312/python.exe" \
        /c/Users/*/AppData/Local/Programs/Python/Python3*/python.exe \
        /c/Program\ Files/Python312/python.exe \
        /c/Program\ Files/Python313/python.exe \
        /c/Windows/py.exe \
        /c/Windows/System32/py.exe
    do
        if python_ok "$cand"; then
            echo "$cand"
            return 0
        fi
    done
    shopt -u nullglob
    if command -v py >/dev/null 2>&1 && py -3 -c "import sys" >/dev/null 2>&1; then
        echo "py"
        return 0
    fi
    for cand in python3; do
        if command -v "$cand" >/dev/null 2>&1 && python_ok "$(command -v "$cand")"; then
            command -v "$cand"
            return 0
        fi
    done
    return 1
}

PY=""
PY="$(find_python || true)"
if [ "$PY" = "py" ]; then
    py -3 -m ensurepip --upgrade || true
    py -3 -m pip install --upgrade meson ninja numpy
elif [ -n "$PY" ]; then
    "$PY" -m ensurepip --upgrade || true
    "$PY" -m pip install --upgrade meson ninja numpy
    PYDIR="$(dirname "$PY")"
    export PATH="$PYDIR:$PYDIR/Scripts:$PATH"
else
    echo "python: no real interpreter found (Store stub ignored)."
    echo "Add:  $WIN_LOCAL/Programs/Python/Python312"
    echo "and:  $WIN_LOCAL/Programs/Python/Python312/Scripts"
    echo "or disable Settings > Apps > App execution aliases > python.exe"
fi

echo
echo "=== apothecary VS host tools ==="
if command -v meson >/dev/null 2>&1; then
    echo "meson: $(meson --version) ($(command -v meson))"
else
    echo "meson: MISSING"
fi
if command -v gum >/dev/null 2>&1; then
    echo "gum: $(gum --version 2>/dev/null || echo ok) ($(command -v gum))"
else
    echo "gum: MISSING (apo menus work without it)"
fi
if command -v ninja >/dev/null 2>&1; then
    echo "ninja: $(ninja --version) ($(command -v ninja))"
else
    echo "ninja: MISSING"
fi
if [ "$PY" = "py" ]; then
    echo "python: $(py -3 --version 2>&1) (py -3)"
elif [ -n "$PY" ]; then
    echo "python: $("$PY" --version 2>&1) ($PY)"
else
    echo "python: MISSING"
fi
echo
if command -v meson >/dev/null 2>&1 && command -v ninja >/dev/null 2>&1; then
    echo "meson + ninja are enough for glon12. Python is only required for angle (gclient)."
fi
echo "Then (Git Bash / MSYS2, from repo root):"
echo "  NO_COLOR=1 UI_ANIM=0 TYPE=vs ARCH=64 ./apo update glon12"
echo "  NO_COLOR=1 UI_ANIM=0 TYPE=vs ARCH=64 ./apo update angle"
