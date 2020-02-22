{ pkgs, lib, config, ... }:

let
  extlinux-conf-builder =
    import (pkgs.path + /nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix) {
      pkgs = pkgs.buildPackages;
    };
  configTxt = pkgs.writeText "config.txt" ''
    # Prevent the firmware from smashing the framebuffer setup
    # done by the mainline kernel when attempting to show low-voltage
    # or overtemperature warnings.
    avoid_warnings=1

    [pi0]
    kernel=u-boot-rpi0.bin

    [pi1]
    kernel=u-boot-rpi1.bin

    [pi2]
    kernel=u-boot-rpi2.bin

    [pi3]
    kernel=u-boot-rpi3.bin
  '';
in {
  sdImage = {
    populateFirmwareCommands = ''
      mkdir -p ./files/boot
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./files/boot
    '';
    populateRootCommands = ''
      (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/boot/)

    '' + lib.optionalString (pkgs.stdenv.hostPlatform.system == "armv6l-linux") ''
      install -D ${pkgs.ubootRaspberryPiZero}/u-boot.bin boot/u-boot-rpi0.bin
      install -D ${pkgs.ubootRaspberryPi}/u-boot.bin boot/u-boot-rpi1.bin
    '' + lib.optionalString (pkgs.stdenv.hostPlatform.system == "armv7l-linux") ''
      install -D ${pkgs.ubootRaspberryPi2}/u-boot.bin boot/u-boot-rpi2.bin
    '' + lib.optionalString (pkgs.stdenv.hostPlatform.system == "aarch64-linux") ''
      install -D ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin boot/u-boot-rpi3.bin
    '' + ''
      install -D ${configTxt} boot/config.txt
    '';
    imageBaseName = "kiosk";
  };

  console.extraTTYs = [ "ttyAMA0" ];

  boot = {
    consoleLogLevel = 7;
    kernelPackages = pkgs.linuxPackages_rpi0;
    kernelParams = [
      "dwc_otg.lpm_enable=0"
      "console=ttyAMA0,115200"
      "rootwait"
      "elevator=deadline"
    ];
    loader.grub.enable = false;
  };

}
