{
  description = "Example Nixiosk System";

  inputs.nixiosk.url = "github:matthewbauer/nixiosk"; # this repo
  inputs.nixpkgs.url = "github:matthewbauer/nixpkgs?ref=kiosk7"; # this is cached in nixiosk.cachix.org

  outputs = { self, nixiosk, nixpkgs }: let

    # Base example configuration
    baseConfig = { pkgs, ... }: {
      imports = [ (nixiosk + /boot/flake.nix) nixiosk.nixosModule ];
      nixiosk.flake = self;
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

    system = "x86_64-linux";

  in {

    # nixos-rebuild looks for nixosConfigurations.$HOST when
    # rebuilding. hostName should match the configuration attribute
    # name.

    # There are lots of configs here. Feel free to remove the ones you
    # don’t need.

    # Any system, built for local system
    nixosConfigurations.example-any = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        ({ ... }: {
          nixiosk.hostName = "example-any";
          nixiosk.hardware = "any";

          boot.loader.grub.enable = false;
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            autoResize = true;
            fsType = "ext4";
          };
        })
      ];
    };

    # .qcow2 image
    nixosConfigurations.example-qemu = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/qemu-no-virtfs.nix)
        ({ ... }: {
          nixiosk.hostName = "example-qemu";
          nixiosk.hardware = "qemu-no-virtfs";
        })
      ];
    };

    nixosConfigurations.example-qemu-virtfs = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/qemu-no-virtfs.nix)
        ({ ... }: {
          nixiosk.hostName = "example-qemu";
          nixiosk.hardware = "qemu";
        })
      ];
    };

    # VirtualBox hardware
    nixosConfigurations.example-ova = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/ova.nix)
        ({ ... }: {
          nixiosk.hostName = "example-ova";
          nixiosk.hardware = "ova";
        })
      ];
    };

    nixosConfigurations.example-iso = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/iso.nix)
        ({ ... }: {
          nixiosk.hostName = "iso";
          nixiosk.hardware = "iso";
        })
      ];
    };

    # pxe image
    nixosConfigurations.example-pxe = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/pxe.nix)
        ({ ... }: {
          nixiosk.hostName = "example-pxe";
          nixiosk.hardware = "pxe";
        })
      ];
    };

    # Raspberry Pi 0
    nixosConfigurations.example-rpi0 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/raspberrypi-uboot.nix)
        ({ ... }: {
          nixiosk.hostName = "example-rpi0";
          nixiosk.hardware = "raspberryPi0";

          # extra stuff for /boot/config.txt
          nixiosk.raspberryPi.firmwareConfig = ''
            dtparam=audio=on
          '';
        })
      ];
    };

    # Raspberry Pi 1
    nixosConfigurations.example-rpi1 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/raspberrypi-uboot.nix)
        ({ ... }: {
          nixiosk.hostName = "example-rpi1";
          nixiosk.hardware = "raspberryPi1";

          # extra stuff for /boot/config.txt
          nixiosk.raspberryPi.firmwareConfig = ''
            dtparam=audio=on
          '';
        })
      ];
    };

    # Raspberry Pi 2
    nixosConfigurations.example-rpi2 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/raspberrypi-uboot.nix)
        ({ ... }: {
          nixiosk.hostName = "example-rpi2";
          nixiosk.hardware = "raspberryPi2";

          # extra stuff for /boot/config.txt
          nixiosk.raspberryPi.firmwareConfig = ''
            dtparam=audio=on
          '';
        })
      ];
    };

    # Raspberry Pi 3
    nixosConfigurations.example-rpi3 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/raspberrypi.nix)
        ({ ... }: {
          nixiosk.hostName = "example-rpi3";
          nixiosk.hardware = "raspberryPi3";

          # extra stuff for /boot/config.txt
          nixiosk.raspberryPi.firmwareConfig = ''
            dtparam=audio=on
          '';
        })
      ];
    };

    # Raspberry Pi 4
    nixosConfigurations.example-rpi4 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/raspberrypi.nix)
        ({ ... }: {
          nixiosk.hostName = "example-rpi4";
          nixiosk.hardware = "raspberryPi4";

          # extra stuff for /boot/config.txt
          nixiosk.raspberryPi.firmwareConfig = ''
            dtparam=audio=on
          '';
        })
      ];
    };

  };

}
