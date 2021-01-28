#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils nixUnstable jq

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$#" -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo Usage: "$0" sdcard nixiosk.json.sample
    exit 1
fi

dev="$1"
shift
dev=$(readlink -f "$dev")

block="/dev/$(basename "$dev")"

flake=
if [ "$#" -gt 0 ] && [ "$1" == "--flake" ]; then
    shift
    flake="${1-.#nixosConfiguration}"
    if [ "$#" -gt 0 ]; then
        shift
    fi
fi

if ! [ -b "$block" ] && ! [[ "$(basename $block)" =~ rdisk* ]]; then
    echo "The device file $block does not exist."
    exit 1
fi

if [ "$(uname)" = Linux ]; then
    if ! [ -f "$dev/dev" ]; then
        dev="/sys/block/$(echo "$dev" | sed s,/dev/,,)"
    fi

    if ! [ -f "$dev/dev" ]; then
        echo "$dev is not a valid device."
        exit 1
    fi

    shopt -s nullglob
    if [ -n "$(echo "$dev"/*/partition)" ]; then
        echo "$dev has parititions! Reformat the table to avoid loss of data."
        echo
        echo "You can remove the partitions with:"
        echo "$ sudo wipefs --all $block"
        echo
        echo "You may need to remove and reinsert the SD card to proceed."
        exit 1
    fi
    shopt -u nullglob
fi

SUDO=
if ! [ -w "$block" ]; then
    echo "Device $block not writable, trying sudo."
    SUDO=sudo
    sudo -v
fi

tmpdir="$(mktemp -d)"
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT

hardware=
custom=
if [ -n "$flake" ]; then
    hardware="$(nix eval --raw "$flake.config.nixiosk.hardware")"
else
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
fi

if ! [[ "$hardware" =~ raspberryPi* ]]; then
    echo "Config must generate an sd image, change hardware value"
    echo "Currently only raspberryPi systems can generate bootable sd images"
    exit 1
fi

if ! [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo No default ssh key exists.
    exit 1
fi

sd_image=
if [ -n "$flake" ]; then
    nix --experimental-features 'nix-command flakes' build "$flake.config.system.build.sdImage" --out-link "$tmpdir/sdImage" "$@"
    sd_image="$(readlink -f $tmpdir/sdImage)"/sd-image/*.img
else
    sd_drv=$(nix-instantiate --no-gc-warning \
                             --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                             "$NIXIOSK/boot" -A config.system.build.sdImage "$@")

    out=$(nix-build --keep-going --no-out-link "$sd_drv" "$@")
    sd_image=$(echo "$out"/sd-image/*.img)
fi

echo "SD image is: $sd_image"

echo "Writing to $dev, may require password."

"$SUDO" dd bs=1M if="$sd_image" of="$block" status=progress conv=fsync
