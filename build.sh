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

hardware="$(jq -r .hardware $custom)"
target=
case "$hardware" in
    qemu-no-virtfs) target=config.system.build.qcow2 ;;
    qemu) target=config.system.build.toplevel ;;
    raspberryPi*) target=config.system.build.sdImage ;;
    pxe) target=config.system.build.netbootIpxeScript ;;
    iso) target=config.system.build.isoImage ;;
    ova) target=config.system.build.virtualBoxOVA ;;
    *) echo "hardware $hardware is not recognized"
       exit 1 ;;
esac

nix-build "$NIXIOSK/boot" --keep-going \
          --arg custom "builtins.fromJSON (builtins.readFile $(realpath $custom))" \
          -A $target "$@"
