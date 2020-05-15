#!/usr/bin/env nix-shell
#!nix-shell -i bash -p rsync coreutils nix

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$1" = --help ]; then
    echo Usage: "$0" nixiosk.json.sample
fi

custom=./nixiosk.json
if [ "$#" -gt 0 ]; then
    custom="$1"
    shift
fi

if ! [ -f "$custom" ]; then
    echo "No custom file provided, $custom does not exist."
    echo "Consult README.md for a template to use."
    exit 1
fi

sd_drv=$(nix-instantiate --no-gc-warning --show-trace \
          --arg custom "builtins.fromJSON (builtins.readFile $custom)" \
          "$NIXIOSK/boot" -A config.system.build.sdImage)

# nix build --keep-going "$sd_drv"
nix-build --keep-going "$sd_drv" "$@"
