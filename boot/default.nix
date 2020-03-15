{ pkgs ? import ../nixpkgs {}
, custom ? builtins.fromJSON (builtins.readFile ../custom.json)
}: import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = ({
    raspberryPi0 = [
      ./raspberrypi-uboot.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi1 = [
      ./raspberrypi-uboot.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi2 = [
      ./raspberrypi-uboot.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi3 = [
      ./raspberrypi-uboot.nix
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
    raspberryPi4 = [
      ({lib, config, pkgs, modulesPath, ...}: import ./raspberrypi.nix { inherit pkgs custom config lib modulesPath; })
      (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ];
  }.${custom.hardware} or (throw "No known booter for ${custom.hardware}."))
  ++ [
    ({pkgs, ...}: import ./basalt.nix ({ inherit pkgs custom; }))
    ../configuration.nix
    ({lib, ...}: {
      system.build = { inherit custom; };
      nixpkgs.localSystem = lib.mkForce { system = builtins.currentSystem; };
    })
  ];
}
