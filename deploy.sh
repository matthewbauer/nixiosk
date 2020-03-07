#!/usr/bin/env nix-shell
#!nix-shell -i bash -p rsync coreutils nix

set -eu -o pipefail

if [ "$#" -ne 1 ]; then
    echo Need to provide device path for SD card
    exit 1
fi

custom=./custom.json
if ! [ -f "$custom" ]; then
    echo No "$custom" provided
    exit 1
fi

dev="$1"
if ! [ -f "$dev/dev" ]; then
    dev="/sys/block/$(echo "$1" | sed s,/dev/,,)"
fi

if ! [ -f "$dev/dev" ]; then
    echo "$dev is not a valid device."
    exit 1
fi

shopt -s nullglob
if [ -n "$(echo "$dev"/*/partition)" ]; then
    echo "$dev has parititions! Reformat the table to avoid loss of data."
    exit 1
fi
shopt -u nullglob

dev=$(readlink -f "$dev")

block="/dev/$(basename "$dev")"

if ! [ -b "$block" ]; then
    echo "The device file $block does not exist."
    exit 1
fi

shift

if ! [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo No default ssh key exists.
    exit 1
fi

sd_drv=$(nix-instantiate --no-gc-warning --show-trace \
          --arg custom "builtins.fromJSON (builtins.readFile $custom)" \
          boot -A config.system.build.sdImage)

sd_image=$(echo "$(nix-build --keep-going --no-out-link "$sd_drv")"/sd-image/*.img)

echo "SD image is: $sd_image"

echo "Writing to $dev, may require password."

SUDO=
if ! [ -w "$block" ]; then
    echo "Device $block not writable, trying sudo."
    SUDO=sudo
fi

"$SUDO" dd bs=1M if="$sd_image" of="$block" status=progress conv=fsync
