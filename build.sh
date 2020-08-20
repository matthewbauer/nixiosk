#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils nix jq

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$#" -gt 0 ] && [ "$1" = --help ]; then
    echo Usage: "$0" nixiosk.json.sample
    exit 1
fi

custom=./nixiosk.json
if [ "$#" -gt 0 ]; then
    custom="$1"
    shift
fi

if ! [ -f "$custom" ]; then
    echo "No custom file provided, $custom does not exist."
    echo "Consult README.org for a template to use."
    exit 1
fi

if ! [[ "$(jq -r .hardware $custom)" =~ "raspberryPi*" ]]; then
    echo "Config $custom must generate an sd image, change hardware value"
    echo "Currently only raspberryPi systems can generate bootable sd images"
    exit 1
fi

sd_drv=$(nix-instantiate --no-gc-warning --show-trace \
          --arg custom "builtins.fromJSON (builtins.readFile $(realpath $custom))" \
          "$NIXIOSK/boot" -A config.system.build.sdImage)

# nix build --keep-going "$sd_drv"
nix-build --keep-going "$sd_drv" "$@"
