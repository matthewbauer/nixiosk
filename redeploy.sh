#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq openssh nix

set -eu -o pipefail

if [ "$1" = --help ]; then
    echo Usage: "$0" retropi1.json retropi1.local
fi

custom=./nixiosk.json
if [ "$#" -gt 0 ]; then
    custom="$1"
    shift
fi

if ! [ -f "$custom" ]; then
    echo No "$custom" provided. Consult README.md for a template to use.
    exit 1
fi

host="$(jq -r .hostName "$custom").local"
if [ "$#" -gt 0 ]; then
    host="$1"
    shift
else
    echo "No host provided, assuming $host"
fi

if ! ssh "root@$host" true; then
    echo "$host is not online. Verify you can reach it via ssh."
    exit 1
fi

sd_drv=$(nix-instantiate --no-gc-warning --show-trace \
          --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
          redeploy.nix -A config.system.build.toplevel)

# nix build --keep-going "$sd_drv"
out=$(nix-build --keep-going --no-out-link "$sd_drv" "$@")

nix copy "$out" --to "ssh://root@$host"

ssh "root@$host" "nix-env -p /nix/var/nix/profiles/system --set $out && $out/bin/switch-to-configuration switch"
