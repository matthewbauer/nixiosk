#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nixUnstable pixiecore jq

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$#" -gt 0 ] && [ "$1" = --help ]; then
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

if [ "$hardware" != "pxe" ]; then
    echo "Config must set hardware to pxe"
    exit 1
fi

sudo -v

pxe_ramdisk=
pxe_kernel=
system=
if [ -n "$flake" ]; then
    tmpdir="$(mktemp -d)"
    cleanup() {
        rm -rf "$tmpdir"
    }
    trap cleanup EXIT

    nix --experimental-features 'nix-command flakes' build "$flake.config.system.build.netbootRamdisk" --out-link $tmpdir/netboot
    pxe_ramdisk=$(readlink -f $tmpdir/netboot)
    nix --experimental-features 'nix-command flakes' build "$flake.config.system.build.kernel" --out-link $tmpdir/kernel
    pxe_kernel=$(readlink -f $tmpdir/kernel)
    nix --experimental-features 'nix-command flakes' build "$flake.config.system.build.toplevel" --out-link $tmpdir/system
    system=$(readlink -f $tmpdir/system)
else
    pxe_ramdisk=$(nix-build --no-gc-warning --no-out-link \
                            --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                            "$NIXIOSK/boot" -A config.system.build.netbootRamdisk)
    pxe_kernel=$(nix-build --no-gc-warning --no-out-link \
                           --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                           "$NIXIOSK/boot" -A config.system.build.kernel)
    system=$(nix-build --no-gc-warning --no-out-link \
                       --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                       "$NIXIOSK/boot" -A config.system.build.toplevel)
fi

sudo pixiecore boot $pxe_kernel/bzImage $pxe_ramdisk/initrd --cmdline "init=$system/init $(cat $system/kernel-params)"
