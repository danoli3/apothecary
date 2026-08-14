#!/usr/bin/env bash
# Map apothecary ARCH to the official Linux release artifact target.
# Usage:
#   source scripts/linux/map_artifact_target.sh
#   map_linux_artifact_target <arch>
# Prints one of:
#   linux_64
#   linux_arm64
#   linux_raspberrypi_arm64
#   linux_raspberrypi_armv6
#   linux_raspberrypi_armv7

map_linux_artifact_target() {
    case "${1:-}" in
        64|x86_64) echo "linux_64" ;;
        arm64) echo "linux_arm64" ;;
        aarch64) echo "linux_raspberrypi_arm64" ;;
        armv6|armv6l) echo "linux_raspberrypi_armv6" ;;
        armv7|armv7l) echo "linux_raspberrypi_armv7" ;;
        *)
            echo "Error: unsupported Linux ARCH '${1:-}' for official artifacts." >&2
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -euo pipefail
    fail=0
    expect() {
        local arch="$1"
        local want="$2"
        local got
        got="$(map_linux_artifact_target "$arch")"
        if [[ "$got" != "$want" ]]; then
            echo "FAIL: ARCH=$arch expected $want got $got" >&2
            fail=1
        else
            echo "OK: ARCH=$arch -> $got"
        fi
    }
    expect 64 linux_64
    expect x86_64 linux_64
    expect arm64 linux_arm64
    expect aarch64 linux_raspberrypi_arm64
    expect armv6l linux_raspberrypi_armv6
    expect armv6 linux_raspberrypi_armv6
    expect armv7l linux_raspberrypi_armv7
    expect armv7 linux_raspberrypi_armv7
    if map_linux_artifact_target jetson >/dev/null 2>&1; then
        echo "FAIL: jetson should not be an official artifact" >&2
        fail=1
    else
        echo "OK: jetson is not an official artifact"
    fi
    exit "$fail"
fi
