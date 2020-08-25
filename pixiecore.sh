#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix pixiecore jq

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

if [ "$(jq -r .hardware $custom)" != "pxe" ]; then
    echo "Config $custom must set hardware to pxe"
    exit 1
fi

sudo -v

pxe_ramdisk=$(nix-build --no-gc-warning --no-out-link \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.netbootRamdisk)

pxe_kernel=$(nix-build --no-gc-warning --no-out-link \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.kernel)

system=$(nix-build --no-gc-warning --no-out-link \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.toplevel)

sudo pixiecore boot $pxe_kernel/bzImage $pxe_ramdisk/initrd --cmdline "init=$system/init"
