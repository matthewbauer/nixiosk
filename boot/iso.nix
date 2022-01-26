{ modulesPath, lib, config, pkgs, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
  ];

  system.build.isoImage = {
    isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    volumeID = lib.substring 0 11 "NIXOS_ISO";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

}
