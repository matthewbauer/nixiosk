#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils nixUnstable jq

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$#" -gt 0 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ] ; }; then
    echo Usage: "$0" nixiosk.json.sample
    exit 1
fi

flake=
if [ "$#" -gt 0 ] && [ "$1" = "--flake" ]; then
    shift
    flake="${1-.#nixosConfiguration}"
    if [ "$#" -gt 0 ]; then
        shift
    fi
fi

hardware=
if [ -n "$flake" ]; then
    hardware="$(nix eval --raw "$flake.config.nixiosk.hardware" ${NIX_OPTIONS:-})"
else
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
    hardware="$(jq -r .hardware $custom)"
fi

target=
case "$hardware" in
    qemu-no-virtfs) target=config.system.build.qcow2 ;;
    qemu) target=config.system.build.toplevel ;;
    raspberryPi*) target=config.system.build.sdImage ;;
    pxe) target=config.system.build.netbootRamdisk ;;
    iso) target=config.system.build.isoImage ;;
    ova) target=config.system.build.virtualBoxOVA ;;
    *) echo "hardware $hardware is not recognized"
       exit 1 ;;
esac

if [ -n "$flake" ]; then
    nix --experimental-features 'nix-command flakes' build "$flake.$target" "$@" ${NIX_OPTIONS:-}
else
    nix-build "$NIXIOSK/boot" \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath $custom))" \
              -A $target "$@" ${NIX_OPTIONS:-}
fi
