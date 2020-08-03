{ modulesPath, lib, config, pkgs, ... }: {

  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  system.build.qcow2 = import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
    inherit lib config pkgs;
    format = "qcow2";
  };

}
