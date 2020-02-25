#!/usr/bin/env sh

if ! [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo No default ssh key exists.
    exit 1
fi

sd_drv=$(nix-instantiate --no-gc-warning --show-trace kiosk.nix \
        --argstr hostName kiosk \
        --arg crossSystem '{ system = "armv6l-linux"; config = "armv6l-unknown-linux-gnueabihf"; }' \
        --arg authorizedKeys "[\"$(cat $HOME/.ssh/id_rsa.pub)\"]" \
        --arg programFunc "pkgs: \"\${pkgs.midori-unwrapped}/bin/midori\"" \
    )

echo drv is "$sd_drv"

# pretty display
nix build --keep-going "$sd_drv"

sd_image=$(nix-build --no-out-link "$sd_drv")

echo "$sd_image"
