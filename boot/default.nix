{ pkgs ? import ../nixpkgs {}
, custom ? builtins.fromJSON (builtins.readFile ../custom.json)
, system ? if builtins.currentSystem == "x86_64-darwin" || builtins.currentSystem == "aarch64-darwin" then "x86_64-linux" else builtins.currentSystem
}: import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    ({
      raspberryPi0 = ./raspberrypi-uboot.nix;
      raspberryPi1 = ./raspberrypi-uboot.nix;
      raspberryPi2 = ./raspberrypi-uboot.nix;
      raspberryPi3 = ./raspberrypi.nix;
      raspberryPi4 = ./raspberrypi.nix;
      ova = ./ova.nix;
      iso = ./iso.nix;
      pxe = ./pxe.nix;
      qemu = ./qemu.nix;
      qemu-no-virtfs = ./qemu-no-virtfs.nix;
    }.${custom.hardware} or (throw "No known booter for ${custom.hardware}."))
    # ./basalt.nix
    ../configuration.nix
    ({lib, ...}: {
      nixiosk = lib.mkForce custom;
      nixpkgs.localSystem = lib.mkForce { inherit system; };
      system.build.redeploy = (import (pkgs.path + /nixos/lib/eval-config.nix) {
        modules = [
          ../configuration.nix
          ({lib, ...}: {
            nixiosk = lib.mkForce custom;
            nixpkgs.localSystem = lib.mkForce { inherit system; };
          })
        ];
      }).config.system.build.toplevel;
    })
  ];
}
