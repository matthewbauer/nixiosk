{ hardware }:

{ pkgs, lib, config, ... }:

{

  hardware = {
    deviceTree = {
      base = "${pkgs.device-tree_rpi}/broadcom";
      overlays = [
        "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/vc4-kms-v3d.dtbo"
      ];
    };
    # enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb pkgs.raspberrypiWirelessFirmware ];
  };

  # environment.systemPackages = [ pkgs.raspberrypi-tools ];

  console.extraTTYs = [ "ttyAMA0" ];

  boot = {
    consoleLogLevel = 7;
    kernelPackages = {
      raspberryPi0 = pkgs.linuxPackages_rpi0;
      raspberryPi1 = pkgs.linuxPackages_rpi1;
      raspberryPi2 = pkgs.linuxPackages_rpi2;
      raspberryPi3 = pkgs.linuxPackages_rpi3;
      raspberryPi4 = pkgs.linuxPackages_rpi4;
    }.${hardware} or (throw "unknown raspberry pi system (${hardware})");
    kernelParams = [
      "dwc_otg.lpm_enable=0"

      # avoids https://github.com/raspberrypi/linux/issues/3331
      "initcall_blacklist=bcm2708_fb_init"

      # avoids https://github.com/raspberrypi/firmware/issues/1247
      "cma=${{
        raspberryPi0 = "256M";
        raspberryPi1 = "256M";
        raspberryPi2 = "256M";
        raspberryPi3 = "512M";
        raspberryPi4 = "512M";
      }.${hardware} or (throw "unknown raspberry pi system (${hardware})")}"
    ];
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" "bcm2835_rng" ];
  };

  nixpkgs.crossSystem = {
    raspberryPi0 = { config = "armv6l-unknown-linux-gnueabihf"; };
    raspberryPi1 = { config = "armv6l-unknown-linux-gnueabihf"; };
    raspberryPi2 = { config = "armv7l-unknown-linux-gnueabihf"; };
    raspberryPi3 = { config = "aarch64-unknown-linux-gnu"; };
    raspberryPi4 = { config = "aarch64-unknown-linux-gnu"; };
  }.${hardware} or (throw "No known crossSystem for ${hardware}.");

}
