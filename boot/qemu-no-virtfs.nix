{ modulesPath, lib, config, pkgs, ... }: {

  system.build.qcow2 = import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
    inherit lib config pkgs;
    format = "qcow2";
    diskSize = 8192;
  };

}
