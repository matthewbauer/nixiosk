#!/usr/bin/env nix-shell
#!nix-shell -i bash -p rsync coreutils nix

set -eu -o pipefail

if [ "$#" -lt 1 ]; then
    echo Need to provide device path for SD card
    exit 1
fi

if [ "$1" = --help ]; then
    echo Usage: "$0" sdcard nixiosk.json.sample
fi

dev="$1"
if ! [ -f "$dev/dev" ]; then
    dev="/sys/block/$(echo "$1" | sed s,/dev/,,)"
fi

if ! [ -f "$dev/dev" ]; then
    echo "$dev is not a valid device."
    exit 1
fi

dev=$(readlink -f "$dev")

block="/dev/$(basename "$dev")"

shopt -s nullglob
if [ -n "$(echo "$dev"/*/partition)" ]; then
    echo "$dev has parititions! Reformat the table to avoid loss of data."
    echo "This can be done with:"
    echo "$ sudo wipefs $block"
    exit 1
fi
shopt -u nullglob

if ! [ -b "$block" ]; then
    echo "The device file $block does not exist."
    exit 1
fi

shift

custom=./nixiosk.json
if [ "$#" -gt 0 ]; then
    custom="$1"
    if [ "${custom:0:2}" != ./ ] && [ "${custom:0:1}" != / ]; then
        custom="./$custom"
    fi
    shift
fi

if ! [ -f "$custom" ]; then
    echo No "$custom" provided. Consult README.md for a template to use.
    exit 1
fi

if ! [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo No default ssh key exists.
    exit 1
fi

SUDO=
if ! [ -w "$block" ]; then
    echo "Device $block not writable, trying sudo."
    SUDO=sudo
    sudo -v
fi

sd_drv=$(nix-instantiate --no-gc-warning --show-trace \
          --arg custom "builtins.fromJSON (builtins.readFile $custom)" \
          boot -A config.system.build.sdImage)

# nix build --keep-going --no-out-link "$sd_drv"
out=$(nix-build --keep-going --no-out-link "$sd_drv" "$@")
sd_image=$(echo "$out"/sd-image/*.img)

echo "SD image is: $sd_image"

echo "Writing to $dev, may require password."

"$SUDO" dd bs=1M if="$sd_image" of="$block" status=progress conv=fsync
