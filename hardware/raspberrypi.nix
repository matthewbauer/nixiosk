{ pkgs, lib, config, ... }:

{

  hardware.deviceTree = {
    base = "${pkgs.device-tree_rpi}/broadcom";
    overlays = [ "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d.dtbo" ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.wireless-regdb ];
  environment.systemPackages = [ pkgs.raspberrypi-tools ];

  console.extraTTYs = [ "ttyAMA0" ];

  boot = {
    consoleLogLevel = 7;
    kernelPackages = {
      "armv6l-linux" = pkgs.linuxPackages_rpi1;
      "armv7l-linux" = pkgs.linuxPackages_rpi2;
      "aarch64-linux" = pkgs.linuxPackages_rpi4;
    }.${pkgs.stdenv.hostPlatform.system} or (throw "unknown raspberry pi system");
    kernelParams = [
      "dwc_otg.lpm_enable=0"

      # avoids https://github.com/raspberrypi/linux/issues/3331
      "initcall_blacklist=bcm2708_fb_init"

      # avoids https://github.com/raspberrypi/firmware/issues/1247
      "cma=${{
        "armv6l-linux" = "256M";
        "armv7l-linux" = "512M";
        "aarch64-linux" = "512M";
      }.${pkgs.stdenv.hostPlatform.system} or (throw "unknown raspberry pi system")}"
    ];
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
  };

}
