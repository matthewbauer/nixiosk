{ pkgs, lib, config, ... }:

let
  extlinux-conf-builder =
    import (pkgs.path + /nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix) {
      pkgs = pkgs.buildPackages;
    };
  configTxt = pkgs.writeText "config.txt" (''
    [pi0]
    kernel=u-boot-rpi0.bin

    [pi1]
    kernel=u-boot-rpi1.bin

    [pi2]
    kernel=u-boot-rpi2.bin

    [pi3]
    kernel=u-boot-rpi3.bin

    [pi4]
    kernel=u-boot-rpi4.bin
    armstub=armstub8-gic.bin

    [all]
    avoid_warnings=1
  '' + pkgs.stdenv.lib.optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
    arm_64bit=1
  '');
in {
  sdImage = {
    compressImage = false;
    populateRootCommands = ''
      mkdir -p files/boot
      ${extlinux-conf-builder} -t 0 -c ${config.system.build.toplevel} -d files/boot
      mkdir -p files/boot/firmware
    '';
    populateFirmwareCommands = ''
      mkdir -p firmware
      install -D ${configTxt} firmware/config.txt

      (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
    '' + {
      armv6l-linux = ''
        install -D ${pkgs.ubootRaspberryPiZero}/u-boot.bin firmware/u-boot-rpi0.bin
        install -D ${pkgs.ubootRaspberryPi}/u-boot.bin firmware/u-boot-rpi1.bin
      '';
      armv7l-linux = ''
        install -D ${pkgs.ubootRaspberryPi2}/u-boot.bin firmware/u-boot-rpi2.bin
        install -D ${pkgs.ubootRaspberryPi3_32bit}/u-boot.bin firmware/u-boot-rpi3.bin
        install -D ${pkgs.ubootRaspberryPi4_32bit}/u-boot.bin firmware/u-boot-rpi4.bin
      '';
      aarch64-linux = ''
        install -D ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin firmware/u-boot-rpi3.bin
        install -D ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
        cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
      '';
    }.${pkgs.stdenv.hostPlatform.system} or (throw "unknown raspberry pi system");
    imageBaseName = "kiosk";
  };

}
