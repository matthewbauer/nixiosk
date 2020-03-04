{ pkgs, lib, config, ... }:

let
  extlinux-conf-builder =
    import (pkgs.path + /nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix) {
      pkgs = pkgs.buildPackages;
    };
  configTxt = pkgs.writeText "config.txt" ''
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
    enable_gic=1
    armstub=armstub8-gic.bin

    [all]
    avoid_warnings=1
    # hdmi_drive=2
    # dtparam=audio=on
    # dtparam=spi=on
    # dtparam=i2c_arm=on
  '' + pkgs.stdenv.lib.optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
    arm_64bit=1
  '';
in {

  hardware.enableRedistributableFirmware = true;

  sdImage = {
    populateRootCommands = ''
      mkdir -p files/boot
      ${extlinux-conf-builder} -t 0 -c ${config.system.build.toplevel} -d files/boot
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

  console.extraTTYs = [ "ttyAMA0" ];

  boot = {
    consoleLogLevel = 7;
    kernelPackages = {
      "armv6l-linux" = pkgs.linuxPackages_rpi1;
      "armv7l-linux" = pkgs.linuxPackages_rpi2;
      "aarch64-linux" = pkgs.linuxPackages_rpi4;
    }.${pkgs.stdenv.hostPlatform.system} or (throw "unknown raspberry pi system");
    kernelParams = [ "dwc_otg.lpm_enable=0" ];
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];

    # avoids https://github.com/raspberrypi/linux/issues/3139
    blacklistedKernelModules = [ "bcm2708_fb" ];
  };

}
