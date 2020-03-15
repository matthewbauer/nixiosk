{ pkgs, lib, config, hardware, ... }:

let
  # vc4-kms and vc4-fkms-v3d seem to work better on different hardware
  # unclear why that is
  gpu-overlay = if builtins.elem hardware ["raspberryPi0" "raspberryPi1" "raspberryPi2"]
                then "vc4-kms-v3d"
                else "vc4-fkms-v3d";
in {

  hardware = {
    deviceTree = {
      base = "${pkgs.device-tree_rpi}/broadcom";
      overlays = [
        "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/${gpu-overlay}.dtbo"
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

  # nixpkgs.overlays = [(self: super: {
  #   mesa = super.mesa.override {
  #     vulkanDrivers = [];
  #     driDrivers = [];
  #     galliumDrivers = ["vc4" "swrast"];
  #     enableRadv = false;
  #     withValgrind = false;
  #   };
  # })];

  nixpkgs.crossSystem = {
    raspberryPi0 = { config = "armv6l-unknown-linux-gnueabihf"; };
    raspberryPi1 = { config = "armv6l-unknown-linux-gnueabihf"; };
    raspberryPi2 = { config = "armv7l-unknown-linux-gnueabihf"; };
    raspberryPi3 = { config = "aarch64-unknown-linux-gnu"; };
    raspberryPi4 = { config = "aarch64-unknown-linux-gnu"; };
  }.${hardware} or (throw "No known crossSystem for ${hardware}.");

  boot.loader.raspberryPi = {
    enable = true;
    version = {
      raspberryPi0 = 0;
      raspberryPi1 = 1;
      raspberryPi2 = 2;
      raspberryPi3 = 3;
      raspberryPi4 = 4;
    }.${hardware} or (throw "No known crossSystem for ${hardware}.");

    # u-boot / extlinux doesn’t work on raspberry pi 4
    uboot.enable = let extlinuxDisabled = [ "raspberryPi4" ];
                   in !(builtins.elem hardware extlinuxDisabled);

    firmwareConfig = ''
      disable_splash=1
    '';
  };

  swapDevices = [{
    device = "/swapfile";
    size = 2048;
  }];

  fileSystems = lib.mkForce (if config.boot.loader.raspberryPi.uboot.enable then {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  } else {
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [ "nofail" "noauto" ];
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  });

}
