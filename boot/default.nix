{ pkgs ? import ../nixpkgs {}
, custom ? builtins.fromJSON (builtins.readFile ../custom.json)
}: import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    ({
      raspberryPi0 = ./boot/raspberrypi.nix;
      raspberryPi1 = ./boot/raspberrypi.nix;
      raspberryPi2 = ./boot/raspberrypi.nix;
      raspberryPi3 = ./boot/raspberrypi.nix;
      raspberryPi4 = ./boot/raspberrypi.nix;
    }.${custom.hardware} or throw "No known booter for ${custom.hardware}.")
    (attrs: import ../basalt.nix (attrs // { inherit custom; }))
    (attrs: import ../configuration.nix (attrs // { inherit custom; }) ) ];
}
