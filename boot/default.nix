{ pkgs ? import ../nixpkgs {}
, custom ? builtins.fromJSON (builtins.readFile ../custom.json)
}: import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    ({
      raspberryPi0 = ./raspberrypi-uboot.nix;
      raspberryPi1 = ./raspberrypi-uboot.nix;
      raspberryPi2 = ./raspberrypi-uboot.nix;
      raspberryPi3 = ./raspberrypi-uboot.nix;
      raspberryPi4 = ./raspberrypi.nix;
      ova = ./ova.nix;
      iso = ./iso.nix;
    }.${custom.hardware} or (throw "No known booter for ${custom.hardware}."))
    ./basalt.nix
    ../configuration.nix
    ({lib, ...}: {
      kioskix = lib.mkForce custom;
      nixpkgs.localSystem = lib.mkForce { system = builtins.currentSystem; };
    })
  ];
}
