{ pkgs ? import ./nixpkgs {}
, custom ? builtins.fromJSON (builtins.readFile ./custom.json)
}: import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    ./configuration.nix
    ({lib, ...}: {
      nixiosk = lib.mkForce custom;
      nixpkgs.localSystem = lib.mkForce {
        system = if builtins.currentSystem == "x86_64-darwin" || builtins.currentSystem == "aarch64-darwin"
                 then "x86_64-linux"
                 else builtins.currentSystem;
      };
    })
  ];
}
