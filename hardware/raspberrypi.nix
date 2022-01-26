{ lib, pkgs, config, ... }:

let
  # u-boot / extlinux doesn’t work on raspberry pi 4, raspberry pi 3
  # looks unstable
  ubootEnabled = !(builtins.elem config.nixiosk.hardware [ "raspberryPi3" "raspberryPi4" ]);

  cma = {
    raspberryPi0 = 256;
    raspberryPi1 = 256;
    raspberryPi2 = 256;
    raspberryPi3 = 256;
    raspberryPi4 = 512;
  }.${config.nixiosk.hardware} or (throw "unknown raspberry pi system (${config.nixiosk.hardware})");

in {

  config = lib.mkIf (builtins.elem config.nixiosk.hardware ["raspberryPi0" "raspberryPi1" "raspberryPi2" "raspberryPi3" "raspberryPi4"]) {


  systemd.services.cec-active-source = {
    enable = config.nixiosk.raspberryPi.cecSupport;
    description = "Set this device to the CEC Active Source";
    wantedBy = ["graphical.target"];
    after = ["cage@tty1.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.runtimeShell} -c '${pkgs.coreutils}/bin/echo on 0 | ${lib.getBin pkgs.libcec}/bin/cec-client -s'";
      ExecStart = "${pkgs.runtimeShell} -c '${pkgs.coreutils}/bin/echo as | ${lib.getBin pkgs.libcec}/bin/cec-client -s'";
    };
  };

  systemd.services.libcec-daemon = {
    enable = config.nixiosk.raspberryPi.cecSupport;
    description = "Set this device to the CEC Active Source";
    wantedBy = ["graphical.target"];
    serviceConfig = {
      ExecStart = "${lib.getBin pkgs.libcec-daemon}/bin/libcec-daemon";
      Type = "simple";
      Restart = "always";
    };
  };

  # Ignore cec power key
  services.logind.extraConfig = lib.optionalString config.nixiosk.raspberryPi.cecSupport ''
    HandlePowerKey = ignore
  '';

  systemd.services.cec-poweroff-tv = {
    enable = config.nixiosk.raspberryPi.cecSupport;
    description = "Use CEC to power off TV";
    wantedBy = [ "poweroff.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.runtimeShell} -c '${pkgs.coreutils}/bin/echo standby 0 | ${lib.getBin pkgs.libcec}/bin/cec-client -s'";
      ExecStop = "${pkgs.runtimeShell} -c '${pkgs.coreutils}/bin/echo standby 0 | ${lib.getBin pkgs.libcec}/bin/cec-client -s'";
    };
  };

  environment.systemPackages = lib.optional config.nixiosk.raspberryPi.cecSupport pkgs.libcec;

  hardware = {
    # set tsched=0 in pulseaudio config to avoid audio glitches
    # see https://wiki.archlinux.org/title/PulseAudio/Troubleshooting#Glitches,_skips_or_crackling
    pulseaudio.configFile = lib.mkOverride 990 (pkgs.runCommand "default.pa" {} ''
      sed 's/module-udev-detect$/module-udev-detect tsched=0/' ${config.hardware.pulseaudio.package}/etc/pulse/default.pa > $out
    '');

    deviceTree = {
      filter = "*rpi*.dtb";
      overlays = [
        {
          name = "cma";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm";
              fragment@0 {
                target = <&cma>;
                __overlay__ {
                  size = <(${toString cma} * 1024 * 1024)>;
                };
              };
            };
          '';
        }
        {
          name = "audio-on-overlay";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm2711";
              fragment@0 {
                target = <&audio>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
        {
          name = "bcm2708";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm2708";
              fragment@1 {
                target = <&fb>;
                __overlay__ {
                  status = "disabled";
                };
              };
              fragment@2 {
                target = <&firmwarekms>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@3 {
                target = <&v3d>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@4 {
                target = <&vc4>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
        {
          name = "bcm2709";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,2709";
              fragment@1 {
                target = <&fb>;
                __overlay__ {
                  status = "disabled";
                };
              };
              fragment@2 {
                target = <&firmwarekms>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@3 {
                target = <&v3d>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@4 {
                target = <&vc4>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
        {
          name = "bcm2710";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm2710";
              fragment@1 {
                target = <&fb>;
                __overlay__ {
                  status = "disabled";
                };
              };
              fragment@2 {
                target = <&firmwarekms>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@3 {
                target = <&v3d>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@4 {
                target = <&vc4>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
        {
          name = "bcm2711";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm2711";
              fragment@1 {
                target = <&fb>;
                __overlay__ {
                  status = "disabled";
                };
              };
              fragment@2 {
                target = <&firmwarekms>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@3 {
                target = <&v3d>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@4 {
                target = <&vc4>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
      ];
    };

    firmware = [
      pkgs.wireless-regdb
      pkgs.raspberrypiWirelessFirmware
    ]
    # early raspberry pis don’t all have builtin wifi, so got to
    # include tons of firmware in case something is plugged into USB
    ++ lib.optionals config.nixiosk.raspberryPi.enableExtraFirmware [
      pkgs.firmwareLinuxNonfree
      pkgs.intel2200BGFirmware
      pkgs.rtl8192su-firmware
      pkgs.rtl8723bs-firmware
      pkgs.rtlwifi_new-firmware
      pkgs.zd1211fw
    ];
  };

  # raspberrypi-tools is kind of big but does have some helpful
  # debugging tools when things go wrong, especially with graphics.
  # environment.systemPackages = [ pkgs.raspberrypi-tools ];

  boot = {
    tmpOnTmpfs = true;
    kernelPackages = {
      raspberryPi0 = pkgs.linuxPackages_rpi0;
      raspberryPi1 = pkgs.linuxPackages_rpi1;
      raspberryPi2 = pkgs.linuxPackages_rpi2;
      raspberryPi3 = pkgs.linuxPackages_rpi3;
      raspberryPi4 = pkgs.linuxPackages_rpi4;
    }.${config.nixiosk.hardware} or (throw "Unknown raspberry pi system (${config.nixiosk.hardware})");
    kernelParams = [
      # appparently this avoids some common bug in Raspberry Pi.
      "dwc_otg.lpm_enable=0"

      "plymouth.ignore-serial-consoles"
    ] ++ lib.optionals ubootEnabled [
        # avoids https://github.com/raspberrypi/linux/issues/3331
        "initcall_blacklist=bcm2708_fb_init"
      ];
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" "bcm2835_rng" ];
  };

  nixpkgs.overlays = [(self: super: lib.optionalAttrs (super.stdenv.hostPlatform != super.stdenv.buildPlatform) {
    # Restrict drivers built by mesa to just the ones we need This
    # reduces the install size a bit.
    mesa = (super.mesa.override {
      vulkanDrivers = [];
      driDrivers = [];
      galliumDrivers = ["v3d" "vc4"];
      withValgrind = false;
      enableOSMesa = false;
      enableGalliumNine = false;
    }).overrideAttrs (o: {
      mesonFlags = (o.mesonFlags or []) ++ ["-Dglx=disabled"];
    });

    libcec = super.libcec.override { inherit (super) libraspberrypi; };

    kodi = (super.kodi.override {
      vdpauSupport = false;
      libva = null;
      raspberryPiSupport = true;
    });

    libcec-daemon = self.callPackage ../pkgs/libcec-daemon {};

  })];

  nixpkgs.crossSystem = {
    raspberryPi0 = { config = "armv6l-unknown-linux-gnueabihf"; };
    raspberryPi1 = { config = "armv6l-unknown-linux-gnueabihf"; };

    # Later versions of the rpi2 does have armv8-a, but leaving this
    # as armv7 for compatibility.
    raspberryPi2 = { config = "armv7l-unknown-linux-gnueabihf"; };

    # rpi3 and rpi4 can use either aarch64 or armv8-a (armv7l).
    raspberryPi3 = { config = "aarch64-unknown-linux-gnu"; };
    raspberryPi4 = { config = "aarch64-unknown-linux-gnu"; };
  }.${config.nixiosk.hardware} or (throw "No known crossSystem for ${config.nixiosk.hardware}.");

  boot.loader.grub.enable = false;
  boot.loader.raspberryPi = {
    enable = true;
    version = {
      raspberryPi0 = 0;
      raspberryPi1 = 1;
      raspberryPi2 = 2;
      raspberryPi3 = 3;
      raspberryPi4 = 4;
    }.${config.nixiosk.hardware} or (throw "No known raspberrypi version for ${config.nixiosk.hardware}.");

    uboot.enable = ubootEnabled;

    firmwareConfig = lib.optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
      arm_64bit=1
    '' + lib.optionalString (config.nixiosk.raspberryPi.firmwareConfig != null) config.nixiosk.raspberryPi.firmwareConfig;
  };

  fileSystems = lib.mkForce (if ubootEnabled then {
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [ "nofail" "noauto" ];
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      autoResize = true;
    };
  } else {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      autoResize = true;
    };
  });

  networking.wireless.enable = true;

  };

}
