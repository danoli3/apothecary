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

rpi_copy_qemu() {
    local root="${1:-${SYSROOT:-}}"
    local qemu="${2:-$(rpi_qemu_static "${RPI_QEMU_ARCH:-aarch64}")}"
    [[ -n "$root" && "$root" != "/" ]] || return 0
    mkdir -p "$root/usr/bin"
    cp "/usr/bin/$qemu" "$root/usr/bin/$qemu"
    chmod +x "$root/usr/bin/$qemu"
}

rpi_ensure_bookworm_script() {
    if [[ -e /usr/share/debootstrap/scripts/bookworm ]]; then
        return 0
    fi
    echo "Host debootstrap has no bookworm script; aliasing a Debian script."
    mkdir -p /usr/share/debootstrap/scripts
    if [[ -e /usr/share/debootstrap/scripts/sid ]]; then
        ln -sf sid /usr/share/debootstrap/scripts/bookworm
    elif [[ -e /usr/share/debootstrap/scripts/stable ]]; then
        ln -sf stable /usr/share/debootstrap/scripts/bookworm
    else
        echo "No debootstrap sid/stable script to alias as bookworm." >&2
        return 1
    fi
}

rpi_bookworm_keyring() {
    # Ubuntu's debian-archive-keyring is older than Debian 12's signing key
    # (F8D2585B8783D481).
    local keyring="${1:-/usr/share/keyrings/debian-archive-bookworm-merged.gpg}"
    mkdir -p "$(dirname "$keyring")" /tmp/debian-archive-keys
    : >/tmp/debian-archive-keys/bookworm.asc
    local key
    for key in archive-key-12.asc archive-key-12-security.asc; do
        curl -fsSL "https://ftp-master.debian.org/keys/${key}" >>/tmp/debian-archive-keys/bookworm.asc
    done
    gpg --batch --dearmor </tmp/debian-archive-keys/bookworm.asc >"$keyring"
    echo "$keyring"
}

rpi_libc_path() {
    local root="${1:-${SYSROOT:-}}"
    local triple="${2:-${GCC_TRIPLE:-aarch64-linux-gnu}}"
    echo "${root}/usr/lib/${triple}/libc.so.6"
}

rpi_debootstrap_bookworm() {
    local deb_arch="$1"
    local root="$2"
    local qemu="$3"
    local mirror="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"
    local suite="${CROSS_OS:-bookworm}"
    local keyring

    rpi_ensure_bookworm_script
    keyring="$(rpi_bookworm_keyring)"
    debootstrap --arch="$deb_arch" --variant=minbase --foreign \
        --keyring="$keyring" \
        "$suite" "$root" "$mirror"
    rpi_copy_qemu "$root" "$qemu"
    local saved_sysroot="${SYSROOT:-}"
    SYSROOT="$root"
    export SYSROOT
    rpi_sysroot_mount "$root"
    rpi_sysroot_run "/debootstrap/debootstrap --second-stage"
    cat >"$root/etc/apt/sources.list" <<EOF
deb ${mirror} ${suite} main contrib
deb ${mirror} ${suite}-updates main contrib
deb http://security.debian.org/debian-security ${suite}-security main contrib
EOF
    rpi_sysroot_umount "$root"
    if [[ -n "$saved_sysroot" ]]; then
        SYSROOT="$saved_sysroot"
        export SYSROOT
    fi
}
