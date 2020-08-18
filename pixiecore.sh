#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix pixiecore jq

set -eu -o pipefail

NIXIOSK="$PWD"

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

pxe_ramdisk=$(nix-build --no-gc-warning --show-trace \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.netbootRamdisk)

pxe_kernel=$(nix-build --no-gc-warning --show-trace \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.kernel)

pxe_script=$(nix-build --no-gc-warning --show-trace \
              --arg custom "builtins.fromJSON (builtins.readFile $(realpath "$custom"))" \
              "$NIXIOSK/boot" -A config.system.build.netbootIpxeScript)

sudo pixiecore boot $pxe_kernel/bzImage $pxe_ramdisk/initrd \
  --cmdline "$(grep -ohP 'init=\S+' $pxe_script/netboot.ipxe) loglevel=4" \
  --debug --dhcp-no-bind --port 64172 --status-port 64172
