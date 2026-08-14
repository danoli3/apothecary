#!/usr/bin/env bash
# Helpers for Raspberry Pi OS sysroots. Source from setup/install/build.
# Expects SYSROOT and, when cross-compiling, qemu-user-static on the host.

rpi_is_native() {
    local model=""
    if [[ -f /proc/device-tree/model ]]; then
        model="$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)"
    fi
    if echo "$model" | grep -qi 'raspberry pi'; then
        return 0
    fi
    if [[ -f /etc/os-release ]] && grep -qiE '^(ID=raspbian|ID_LIKE=.*raspbian|PRETTY_NAME=.*Raspberry Pi)' /etc/os-release; then
        return 0
    fi
    return 1
}

rpi_qemu_static() {
    case "${1:-aarch64}" in
        aarch64|arm64) echo "qemu-aarch64-static" ;;
        armv6l|armv7l|armhf|armel) echo "qemu-arm-static" ;;
        *) echo "qemu-aarch64-static" ;;
    esac
}

rpi_sysroot_mount() {
    local root="${1:-${SYSROOT:-}}"
    [[ -n "$root" && "$root" != "/" ]] || return 0
    mkdir -p "$root/proc" "$root/sys" "$root/dev" "$root/dev/pts"
    mountpoint -q "$root/proc" || mount -t proc proc "$root/proc"
    mountpoint -q "$root/sys" || mount -t sysfs sys "$root/sys"
    mountpoint -q "$root/dev" || mount --bind /dev "$root/dev"
    mountpoint -q "$root/dev/pts" || mount --bind /dev/pts "$root/dev/pts"
    if [[ -f /etc/resolv.conf ]]; then
        mkdir -p "$root/etc"
        cp -L /etc/resolv.conf "$root/etc/resolv.conf"
    fi
}

rpi_sysroot_umount() {
    local root="${1:-${SYSROOT:-}}"
    [[ -n "$root" && "$root" != "/" ]] || return 0
    for mp in "$root/dev/pts" "$root/dev" "$root/proc" "$root/sys"; do
        if mountpoint -q "$mp"; then
            umount -l "$mp" || true
        fi
    done
}

rpi_sysroot_run() {
    local root="${SYSROOT:-/}"
    if [[ "$root" == "/" ]] || rpi_is_native; then
        bash -lc "$*"
        return
    fi
    local qemu
    qemu="$(rpi_qemu_static "${RPI_QEMU_ARCH:-aarch64}")"
    if [[ ! -x "$root/usr/bin/$qemu" ]]; then
        mkdir -p "$root/usr/bin"
        cp "/usr/bin/$qemu" "$root/usr/bin/$qemu"
        chmod +x "$root/usr/bin/$qemu"
    fi
    chroot "$root" "/usr/bin/$qemu" /bin/bash -lc "$*"
}
