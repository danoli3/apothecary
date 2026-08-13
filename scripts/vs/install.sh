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

# winget exits non-zero when the package is already installed / no upgrade.
# That is not a failure for this script.
winget_ensure() {
    local id="$1"
    if winget list -e --id "$id" >/dev/null 2>&1; then
        echo "winget: $id already installed"
        return 0
    fi
    winget install -e --id "$id" --accept-package-agreements --accept-source-agreements || {
        echo "winget: $id install returned $? (already installed is ok)"
        return 0
    }
}

if command -v winget >/dev/null 2>&1; then
    winget_ensure Microsoft.WindowsTerminal
    winget_ensure Ninja-build.Ninja
    winget_ensure mesonbuild.Meson
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
        unzip \
        python3
fi

if [ "${GITHUB_ACTIONS:-0}" = 0 ]; then

    if command -v python >/dev/null 2>&1; then
        python -m ensurepip --upgrade
        python -m pip install --upgrade meson ninja numpy
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m pip --version 2>/dev/null
        python3 -m pip install --upgrade meson ninja numpy
    else
        echo "python is not installed. Skipping pip meson/ninja/numpy."
    fi

fi

echo
echo "=== apothecary VS host tools ==="
command -v meson >/dev/null && meson --version || echo "meson: MISSING (open a new shell after winget, or: pip install meson ninja)"
command -v ninja >/dev/null && ninja --version || echo "ninja: MISSING"
command -v python3 >/dev/null && python3 --version || command -v python >/dev/null && python --version || echo "python: MISSING"
echo
echo "Then (Git Bash / MSYS2, from repo root):"
echo "  NO_COLOR=1 UI_ANIM=0 TYPE=vs ARCH=64 ./apo update glon12"
echo "  NO_COLOR=1 UI_ANIM=0 TYPE=vs ARCH=64 ./apo update angle"
