#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix qemu jq

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$#" -gt 0 ] && [ "$1" = --help ]; then
    echo Usage: "$0" nixiosk.json.sample
    exit 1
fi

custom=./nixiosk.json
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
if ! [[ "$hardware" = qemu* ]]; then
    echo "Config $custom must set hardware to qemu"
    exit 1
fi

if [ "$hardware" = qemu ] && ! [ "$(uname)" = Linux ]; then
    echo "Set hardware to qemu-no-virtfs on non-Linux systems"
    exit 1
fi

hostName="$(jq -r .hostName "$custom")"

system=$(nix-build --no-gc-warning --no-out-link --show-trace \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.toplevel)

NIX_DISK_IMAGE=
if [ "$hardware" = qemu-no-virtfs ]; then
    NIX_DISK_IMAGE=${NIX_DISK_IMAGE:-$(mktemp $TMPDIR/XXXXXXXXX.qcow2)}
    qcow2=$(nix-build --no-gc-warning --no-out-link --show-trace \
                      --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                      "$NIXIOSK/boot" -A config.system.build.qcow2)/nixos.qcow2
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

if [ "$(uname)" = Darwin ]; then
    qemuFlags+=" -accel hvf"
else
    qemuFlags+=" -cpu max"
fi

if [ "$(uname)" = Linux ] && ! [ -e /dev/kvm ]; then
    echo "Warning: qemu will be very slow without Linux KVM support"
fi

qemu-kvm -name "$hostName" -m 384 \
  -vga virtio \
  -nic user \
  -device virtio-rng-pci \
  -device virtio-tablet-pci \
  -device virtio-keyboard-pci \
  -soundhw all \
  -kernel $system/kernel -initrd $system/initrd \
  -append "$(cat $system/kernel-params) init=$system/init" \
  $qemuFlags "$@"
