{
  description = "Example Nixiosk System";

  inputs.nixiosk.url = "github:matthewbauer/nixiosk"; # this repo
  inputs.nixpkgs.url = "github:matthewbauer/nixpkgs?ref=kiosk6"; # this is cached in nixiosk.cachix.org

  outputs = { self, nixiosk, nixpkgs }: let
    # can only build on Linux currently
    systems = [ "x86_64-linux" ];

    forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; } );

    # Base example configuration
    baseConfig = { pkgs, ... }: {
      imports = [ nixiosk.nixosModule ];
      nixiosk.locale = {
        lang = "en_US.UTF-8";
        regDom = "US";
        timeZone = "America/Chicago";
      };
      nixiosk.program = {
        executable = "/bin/kodi";
        package = pkgs.kodi;
      };
    };

  in {

    # “packages” are needed to make system booter images. Once they’re
    # booted, you can just use nixos-rebuild like usual.
    packages = forAllSystems (system: let
      # Base config needed for booting a new system
      commonModule = ({...}: {
        nixpkgs.localSystem = { inherit system; };
        nixiosk.flake = self;
        imports = [ (nixiosk + /boot/flake.nix) ];
      });
    in {
      rpi0-sdImage = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-rpi0
          (nixiosk + /boot/raspberrypi-uboot.nix)
        ];
      }).config.system.build.sdImage;
      rpi1-sdImage = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-rpi1
          (nixiosk + /boot/raspberrypi-uboot.nix)
        ];
      }).config.system.build.sdImage;
      rpi2-sdImage = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-rpi2
          (nixiosk + /boot/raspberrypi-uboot.nix)
        ];
      }).config.system.build.sdImage;
      rpi3-sdImage = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-rpi3
          (nixiosk + /boot/raspberrypi.nix)
        ];
      }).config.system.build.sdImage;
      rpi4-sdImage = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-rpi4
          (nixiosk + /boot/raspberrypi.nix)
        ];
      }).config.system.build.sdImage;
      qcow2 = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-qemu
          (nixiosk + /boot/qemu-no-virtfs.nix)
        ];
      }).config.system.build.qcow2;
      isoImage = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-any
          (nixiosk + /boot/iso.nix)
        ];
      }).config.system.build.isoImage;
      virtualBoxOVA = (nixpkgs.lib.nixosSystem {
        modules = [
          commonModule
          self.nixosConfigurations.example-ova
          (nixiosk + /boot/ova.nix)
        ];
      }).config.system.build.virtualBoxOVA;
    });

    # nixos-rebuild looks for nixosConfigurations.$HOST when
    # rebuilding. hostName should match the configuration attribute
    # name.

    # There are lots of configs here. Feel free to remove the ones you
    # don’t need.

    # Any system, built for local system
    nixosConfigurations.example-any = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-any";
      nixiosk.hardware = "any";
    };

    # .qcow2 image
    nixosConfigurations.example-qemu = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-qemu";
      nixiosk.hardware = "qemu-no-virtfs";
    };

    # VirtualBox hardware
    nixosConfigurations.example-ova = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-ova";
      nixiosk.hardware = "ova";
    };

    # Raspberry Pi 0
    nixosConfigurations.example-rpi0 = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-rpi0";
      nixiosk.hardware = "raspberryPi0";

      # extra stuff for /boot/config.txt
      nixiosk.raspberryPi.firmwareConfig = ''
        dtparam=audio=on
      '';
    };

    # Raspberry Pi 1
    nixosConfigurations.example-rpi1 = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-rpi1";
      nixiosk.hardware = "raspberryPi1";

      # extra stuff for /boot/config.txt
      nixiosk.raspberryPi.firmwareConfig = ''
        dtparam=audio=on
      '';
    };

    # Raspberry Pi 2
    nixosConfigurations.example-rpi2 = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-rpi2";
      nixiosk.hardware = "raspberryPi2";
      nixiosk.raspberryPi.firmwareConfig = ''
        dtparam=audio=on
      '';
    };

    # Raspberry Pi 3
    nixosConfigurations.example-rpi3 = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-rpi3";
      nixiosk.hardware = "raspberryPi3";
      nixiosk.raspberryPi.firmwareConfig = ''
        dtparam=audio=on
      '';
    };

    # Raspberry Pi 4
    nixosConfigurations.example-rpi4 = { pkgs, ... }: {
      imports = [ baseConfig ];
      nixiosk.hostName = "example-rpi4";
      nixiosk.hardware = "raspberryPi4";
      nixiosk.raspberryPi.firmwareConfig = ''
        dtparam=audio=on
      '';
    };

  };

}
