#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix jq gnused qemu

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$#" -gt 0 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ] ; }; then
    echo Usage: "$0" nixiosk.json.sample
    exit 1
fi

vnc=
if [ "$#" -gt 0 ] && [ "$1" = --vnc ]; then
    vnc=1
    shift
fi

flake=
if [ "$#" -gt 0 ] && [ "$1" = --flake ]; then
    shift
    flake="${1-.#nixosConfiguration}"
    if [ "$#" -gt 0 ]; then
        shift
    fi
fi

tmpdir="$(mktemp -d)"
hardware=
hostName=
qemuArch=
NIX_DISK_IMAGE=

cleanup() {
    rm -rf "$tmpdir"
    if [ "$hardware" = qemu-no-virtfs ] && [ -n "$NIX_DISK_IMAGE" ]; then
        rm -f "$NIX_DISK_IMAGE"
    fi
}
trap cleanup EXIT

custom=./nixiosk.json

if [ -n "$flake" ]; then
    hardware="$(nix eval --raw "$flake.config.nixiosk.hardware")"
    hostName="$(nix eval --raw "$flake.config.nixiosk.hostName")"
    qemuArch="$(nix eval --raw "$flake._module.args.pkgs.hostPlatform.qemuArch")"
else
    if [ "$#" -gt 0 ]; then
        if [ "${1:0:1}" != "-" ]; then
            custom="$1"
            shift
        fi
    fi

    if ! [ -f "$custom" ]; then
        echo "No custom file provided, $custom does not exist."
        echo "Consult README.org for a template to use."
        exit 1
    fi

    hardware="$(jq -r .hardware $custom)"
    hostName="$(jq -r .hostName "$custom")"
fi

if ! [[ "$hardware" = qemu* ]]; then
    echo "Config $custom must set hardware to qemu"
    exit 1
fi

if [ "$hardware" = qemu ] && ! [ "$(uname)" = Linux ]; then
    echo "Set hardware to qemu-no-virtfs on non-Linux systems"
    exit 1
fi

system=
if [ -n "$flake" ]; then
    nix --experimental-features 'nix-command flakes' build "$flake.config.system.build.toplevel" --out-link "$tmpdir/system" ${NIX_OPTIONS:-}
    system=$(readlink -f $tmpdir/system)
else
    qemuArch=$(nix-instantiate --no-gc-warning \
                       --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                       "$NIXIOSK/boot" --eval -A _module.args.pkgs.hostPlatform.qemuArch ${NIX_OPTIONS:-} | sed 's,^",,; s,"$,,')
    system=$(nix-build --no-gc-warning --no-out-link \
                       --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                       "$NIXIOSK/boot" -A config.system.build.toplevel ${NIX_OPTIONS:-})
fi

if [ "$hardware" = qemu-no-virtfs ]; then
    NIX_DISK_IMAGE=${NIX_DISK_IMAGE:-$tmpdir/nixos.qcow2}
    qcow2=
    if [ -n "$flake" ]; then
        nix --experimental-features 'nix-command flakes' build "$flake.config.system.build.qcow2" --out-link "$tmpdir/qcow2" ${NIX_OPTIONS:-}
        qcow2=$(readlink -f $tmpdir/qcow2)/nixos.qcow2
    else
        qcow2=$(nix-build --no-gc-warning --no-out-link \
                          --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                          "$NIXIOSK/boot" -A config.system.build.qcow2 ${NIX_OPTIONS:-})/nixos.qcow2
    fi

    cp -f $qcow2 $NIX_DISK_IMAGE
    chmod +w $NIX_DISK_IMAGE
else
    NIX_DISK_IMAGE=${NIX_DISK_IMAGE:-./$hostName.qcow2}
    if ! test -e "$NIX_DISK_IMAGE"; then
        qemu-img create -f qcow2 "$NIX_DISK_IMAGE" 512M
    fi
fi

qemuFlags=
if [ "$hardware" = qemu-no-virtfs ]; then
    qemuFlags+=" -drive if=virtio,file=$NIX_DISK_IMAGE,werror=report"
else
    qemuFlags+=" -virtfs local,path=/nix/store,security_model=none,mount_tag=store"
    qemuFlags+=" -drive id=drive0,if=none,file=$NIX_DISK_IMAGE"
    qemuFlags+=" -device virtio-blk-pci,werror=report,drive=drive0"
fi

if [ "$(uname -s)" = Darwin ] && { [ "$(uname -s)" = arm64 ] && [ "$qemuArch" = aarch64 ] || [ "$(uname -s)" = "$qemuArch" ] ; }; then
    qemuFlags+=" -accel hvf"
else
    qemuFlags+=" -cpu max"
fi

if [ -n "$vnc" ]; then
    qemuFlags+=" -vnc :0,password"
    qemuFlags+=" -monitor stdio"
fi

if [ "$(uname -s)" = Linux ]; then
    if [ -e /dev/kvm ]; then
        qemuFlags+=" -enable-kvm"
    else
        echo "Warning: qemu will be very slow without Linux KVM support"
    fi
fi

if [ "$qemuArch" = aarch64 ]; then
    qemuFlags+=" -machine virt"
    qemuFlags+=" -device virtio-gpu-pci"
else
    qemuFlags+=" -vga virtio"
fi

"qemu-system-$qemuArch" -name "$hostName" -m 1024 \
  -nic user \
  -device virtio-rng-pci \
  -device virtio-tablet-pci \
  -device virtio-keyboard-pci \
  -device virtio-balloon \
  -soundhw all \
  -display default,show-cursor=on \
  -kernel $system/kernel -initrd $system/initrd \
  -append "$(cat $system/kernel-params) init=$system/init" \
  $qemuFlags "$@"
