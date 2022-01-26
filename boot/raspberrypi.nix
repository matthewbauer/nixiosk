{ pkgs, lib, config, modulesPath, ... }:

let
  raspberrypi-conf-builder =
    import (modulesPath + "/system/boot/loader/raspberrypi/raspberrypi-builder.nix") {
      pkgs = pkgs.buildPackages;
      firmware = pkgs.raspberrypifw;
      configTxt = pkgs.writeText "config.txt" (''
        kernel=kernel.img
        initramfs initrd followkernel
      '' + config.boot.loader.raspberryPi.firmwareConfig);
    };
in {
  imports = [ (modulesPath + "/installer/sd-card/sd-image.nix") ];

  boot.loader.raspberryPi.enable = lib.mkForce false;

  sdImage = {
    compressImage = false;
    firmwareSize = 128;
    populateFirmwareCommands = "${raspberrypi-conf-builder} -c ${config.system.build.toplevel} -d firmware";
    populateRootCommands = "";
    imageBaseName = "${config.nixiosk.hostName}-${config.nixiosk.hardware}";
  };

}
