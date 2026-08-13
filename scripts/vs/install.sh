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

# Real interpreter only. WindowsApps\python.exe is a Store stub that prints
# "Python was not found" and exits 9009 — command -v still finds it.
python_ok() {
    local bin="$1"
    [ -n "$bin" ] || return 1
    "$bin" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >/dev/null 2>&1
}

find_python() {
    local cand
    for cand in \
        "${LOCALAPPDATA}/Programs/Python/Python312/python.exe" \
        "${LOCALAPPDATA}/Programs/Python/Python313/python.exe" \
        "/c/Program Files/Python312/python.exe" \
        "/c/Program Files/Python313/python.exe"
    do
        if python_ok "$cand"; then
            echo "$cand"
            return 0
        fi
    done
    if command -v py >/dev/null 2>&1 && py -3 -c "import sys" >/dev/null 2>&1; then
        echo "py"
        return 0
    fi
    for cand in python3 python; do
        if command -v "$cand" >/dev/null 2>&1 && python_ok "$(command -v "$cand")"; then
            command -v "$cand"
            return 0
        fi
    done
    return 1
}

if [ "${GITHUB_ACTIONS:-0}" = 0 ]; then
    PY="$(find_python || true)"
    if [ "$PY" = "py" ]; then
        py -3 -m ensurepip --upgrade
        py -3 -m pip install --upgrade meson ninja numpy
    elif [ -n "$PY" ]; then
        "$PY" -m ensurepip --upgrade
        "$PY" -m pip install --upgrade meson ninja numpy
    else
        echo "python is not on PATH (Store stub does not count). Skipping pip meson/ninja."
        echo "Open a new shell after winget, or add Python312 to PATH."
    fi
fi

echo
echo "=== apothecary VS host tools ==="
command -v meson >/dev/null && meson --version || echo "meson: MISSING (open a new shell after winget, or: pip install meson ninja)"
command -v ninja >/dev/null && ninja --version || echo "ninja: MISSING"
if PY="$(find_python || true)"; then
    if [ "$PY" = "py" ]; then py -3 --version; else "$PY" --version; fi
else
    echo "python: MISSING (disable Settings > Apps > App execution aliases > python.exe)"
fi
echo
echo "Then (Git Bash / MSYS2, from repo root):"
echo "  NO_COLOR=1 UI_ANIM=0 TYPE=vs ARCH=64 ./apo update glon12"
echo "  NO_COLOR=1 UI_ANIM=0 TYPE=vs ARCH=64 ./apo update angle"
