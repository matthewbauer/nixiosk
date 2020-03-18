{ lib, pkgs, config, ... }:

let
  # u-boot / extlinux doesn’t work on raspberry pi 4
  ubootEnabled = !(builtins.elem config.kioskix.hardware [ "raspberryPi4" ]);

  # vc4-kms and vc4-fkms-v3d seem to work better on different hardware
  # unclear why that is. Manually tested each on my rpi0 and rpi4.
  gpu-overlay = if builtins.elem config.kioskix.hardware ["raspberryPi0" "raspberryPi1" "raspberryPi2"]
                then "vc4-kms-v3d"
                else "vc4-fkms-v3d";

  gpu-mem = {
    raspberryPi0 = 120;
    raspberryPi1 = 120;
    raspberryPi2 = 120;
    raspberryPi3 = 220;
    raspberryPi4 = 320;
  };
in {

  config = lib.mkIf (builtins.elem config.kioskix.hardware ["raspberryPi0" "raspberryPi1" "raspberryPi2" "raspberryPi3" "raspberryPi4"])
    {

  hardware = {
    # hardware.deviceTree overlaps with raspberry pi config.txt, but
    # only hardware.deviceTree works with U-Boot
    deviceTree = {
      base = "${pkgs.device-tree_rpi}/broadcom";
      overlays = [
        "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/${gpu-overlay}.dtbo"
      ];
    };

    # linux-firmware-nonfree is pretty big (500M+), so we don’t
    # include it It’s not needed for Raspberry Pi itself but some
    # addons may not work as a result
    # enableRedistributableFirmware = true;

    firmware = [ pkgs.wireless-regdb pkgs.raspberrypiWirelessFirmware ];
  };

  # raspberrypi-tools is kind of big but does have some helpful
  # debugging tools when things go wrong, especially with graphics.
  # environment.systemPackages = [ pkgs.raspberrypi-tools ];

  # tty serial port, unused right now, but may be useful for
  # debugging.
  console.extraTTYs = [ "ttyAMA0" ];

  boot = {
    kernelPackages = {
      raspberryPi0 = pkgs.linuxPackages_rpi0;
      raspberryPi1 = pkgs.linuxPackages_rpi1;
      raspberryPi2 = pkgs.linuxPackages_rpi2;
      raspberryPi3 = pkgs.linuxPackages_rpi3;
      raspberryPi4 = pkgs.linuxPackages_rpi4;
    }.${config.kioskix.hardware} or (throw "Unknown raspberry pi system (${config.kioskix.hardware})");
    kernelParams = [
      # appparently this avoids some common bug in Raspberry Pi.
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
      }.${config.kioskix.hardware} or (throw "unknown raspberry pi system (${config.kioskix.hardware})")}"
    ];
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" "bcm2835_rng" ];
  };

  nixpkgs.overlays = [(self: super: (lib.optionalAttrs (super.stdenv.hostPlatform != super.stdenv.buildPlatform) {
    # Restrict drivers built by mesa to just the ones we need This
    # reduces the install size a bit.
    mesa = (super.mesa.override {
      vulkanDrivers = [];
      driDrivers = [];
      galliumDrivers = ["vc4" "swrast"];
      enableRadv = false;
      withValgrind = false;
      enableOSMesa = false;
      enableGalliumNine = false;
    }).overrideAttrs (o: {
      mesonFlags = (o.mesonFlags or []) ++ ["-Dglx=disabled"];
    });
  }))];

  nixpkgs.crossSystem = {
    raspberryPi0 = { config = "armv6l-unknown-linux-gnueabihf"; };
    raspberryPi1 = { config = "armv6l-unknown-linux-gnueabihf"; };
    raspberryPi2 = { config = "armv7l-unknown-linux-gnueabihf"; };
    raspberryPi3 = { config = "aarch64-unknown-linux-gnu"; };
    raspberryPi4 = { config = "aarch64-unknown-linux-gnu"; };
  }.${config.kioskix.hardware} or (throw "No known crossSystem for ${config.kioskix.hardware}.");

  boot.loader.raspberryPi = {
    enable = true;
    version = {
      raspberryPi0 = 0;
      raspberryPi1 = 1;
      raspberryPi2 = 2;
      raspberryPi3 = 3;
      raspberryPi4 = 4;
    }.${config.kioskix.hardware} or (throw "No known raspberrypi version for ${config.kioskix.hardware}.");

    uboot.enable = ubootEnabled;

    firmwareConfig = ''
      disable_splash=1
      dtoverlay=${gpu-overlay}
      dtparam=audio=on
      gpu_mem=${toString gpu-mem}
    '' + pkgs.stdenv.lib.optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
      arm_64bit=1
    '';
  };

  # swapDevices = [{
  #   device = "/swapfile";
  #   size = 2048;
  # }];

  fileSystems = lib.mkForce (if ubootEnabled then {
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [ "nofail" "noauto" ];
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  } else {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  });

  };

}
