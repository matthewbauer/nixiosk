{ pkgs ? import ../nixpkgs {}
, custom ? builtins.fromJSON (builtins.readFile ../custom.json)
}: import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = ({
    raspberryPi0 = [
      ./raspberrypi.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi1 = [
      ./raspberrypi.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi2 = [
      ./raspberrypi.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi3 = [
      ./raspberrypi.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi4 = [
      ./raspberrypi.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
  }.${custom.hardware} or (throw "No known booter for ${custom.hardware}."))
  ++ [
    # ({pkgs, ...}: import ./basalt.nix ({ inherit pkgs custom; }))
    ({pkgs, lib, config, ...}:
      import ../configuration.nix { inherit pkgs lib config custom; } )
  ];
}
