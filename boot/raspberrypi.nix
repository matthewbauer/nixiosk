{ pkgs, lib, config, modulesPath, ... }:

let
  raspberrypi-conf-builder =
    import (modulesPath + "/system/boot/loader/raspberrypi/raspberrypi-builder.nix") {
      pkgs = pkgs.buildPackages;
      raspberrypifw = pkgs.raspberrypifw;
      configTxt = pkgs.writeText "config.txt" (''
        avoid_warnings=1
        enable_uart=1
        disable_splash=1
        kernel=kernel.img
        initramfs initrd followkernel
        gpu_mem=320
        dtoverlay=vc4-fkms-v3d
        dtparam=audio=on
      '' + lib.optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
        arm_64bit=1
      '');
    };
in {
  boot.loader.raspberryPi.enable = lib.mkForce false;

  sdImage = {
    compressImage = false;
    firmwareSize = 128;
    populateFirmwareCommands = "${raspberrypi-conf-builder} -c ${config.system.build.toplevel} -d firmware";
    populateRootCommands = "";
    imageBaseName = "kiosk";
  };

}
