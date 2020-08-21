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

if [ "$(jq -r .hardware $custom)" != "qemu" ]; then
    echo "Config $custom must set hardware to qemu"
    exit 1
fi

hostName="$(jq -r .hostName "$custom")"

system=$(nix-build --no-gc-warning --no-out-link --show-trace \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.toplevel)

NIX_DISK_IMAGE=$(readlink -f ${NIX_DISK_IMAGE:-./$hostName.qcow2})

if ! test -e "$NIX_DISK_IMAGE"; then
  qemu-img create -f qcow2 "$NIX_DISK_IMAGE" 512M
fi

mkdir -p ${XCHG_DIR:-./xchg}

qemu-kvm -name $hostName -m 384 \
  -drive index=0,id=drive0,if=none,file=$NIX_DISK_IMAGE \
  -device virtio-blk-pci,werror=report,drive=drive0 \
  -device virtio-net,netdev=vmnic -netdev user,id=vmnic \
  -device virtio-rng-pci \
  -virtfs local,path=/nix/store,security_model=none,mount_tag=store \
  -virtfs local,path=${XCHG_DIR:-./xchg},security_model=none,mount_tag=xchg \
  -virtfs local,path=${XCHG_DIR:-./xchg},security_model=none,mount_tag=shared \
  -usb -device usb-tablet,bus=usb-bus.0 \
  -kernel $system/kernel -initrd $system/initrd \
  -append "$(cat $system/kernel-params) init=$system/init ttyS0,115200n8 tty0" \
  "$@"
