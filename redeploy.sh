#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq openssh nixUnstable

set -eu -o pipefail

NIXIOSK="$PWD"

if [ "$#" -gt 0 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ] ; }; then
    echo Usage: "$0" retropi1.json retropi1.local
    exit 1
fi

flake=
if [ "$#" -gt 0 ] && [ "$1" = --flake ]; then
    shift
    flake="${1-.#nixosConfiguration}"
    if [ "$#" -gt 0 ]; then
        shift
    fi
fi

custom=./nixiosk.json
if [ -z "$flake" ]; then
    if [ "$#" -gt 0 ]; then
        custom="$1"
        shift
    fi

    if ! [ -f "$custom" ]; then
        echo No "$custom" provided. Consult README.org for a template to use.
        exit 1
    fi
fi

host=
if [ "$#" -gt 0 ]; then
    if [ "${1:0:1}" != "-" ]; then
        host="$1"
        shift
    fi
fi

if [ -z "$host" ]; then
    host=
    if [ -n "$flake" ]; then
        host="$(nix eval --raw "$flake.config.nixiosk.hostName").local"
    else
        host="$(jq -r .hostName "$custom").local"
    fi
    echo "No host provided, assuming $host"
fi

if ! ssh "root@$host" true; then
    echo "$host is not online. Verify you can reach it via ssh."
    exit 1
fi

system=
if [ -n "$flake" ]; then
    if [ -z "$(nix eval --raw "$flake.config.system.build.installBootLoader" 2>/dev/null)" ]; then
        echo "$flake is does not have a boot loader. Suggestion: remove /boot/raspberrypi.nix from modules."
        exit 1
    fi

    tmpdir="$(mktemp -d)"
    cleanup() {
        rm -rf "$tmpdir"
    }
    trap cleanup EXIT

    nix --experimental-features 'nix-command flakes' build "$flake.config.system.build.redeploy" --out-link "$tmpdir/system" "$@" ${NIX_OPTIONS:-}
    system=$(readlink -f $tmpdir/system)
else
    drv=$(nix-instantiate --no-gc-warning \
                             --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
                             "$NIXIOSK/redeploy.nix" -A config.system.build.toplevel ${NIX_OPTIONS:-})

    # nix build --keep-going "$system"
    system=$(nix-build --keep-going --no-out-link "$system" "$@" ${NIX_OPTIONS:-})
fi

nix copy "$system" --to "ssh://root@$host"
ssh "root@$host" "nix-env -p /nix/var/nix/profiles/system --set $system && $system/bin/switch-to-configuration switch"
