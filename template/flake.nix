###
### THIS IS AN EXAMPLE NIXIOSK CONFIG
###
### You can use it as is, but most likely you will want to add your own customizations.
### Make sure to use with nixiosk cachix (https://app.cachix.org/cache/nixiosk).
###

{
  description = "Example Nixiosk System";

  inputs.nixiosk.url = "github:matthewbauer/nixiosk";
  inputs.nixpkgs.url = "github:matthewbauer/nixpkgs?ref=kiosk7";

  outputs = { self, nixiosk, nixpkgs }: let

    # Base example configuration
    baseConfig = { pkgs, ... }: {
      imports = [ (nixiosk + /boot/flake.nix) nixiosk.nixosModule ];
      nixiosk.flake = self;

      ###
      ### Provide your own executablef here!
      ###
      nixiosk.program = {
        package = pkgs.kodi;
        executable = "/bin/kodi";
      };

      nixiosk.authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC56m+QOu+6NERnopje0TJHVv7NSJna1pFNQjqAimRte4zXtYhiVMCPPtlSM1M4LCTDe409Q0Y0zuZc+kNEZSjyQfy9Bd6QXGtYTq+5U+oJZWn5yfvVXOcaMgAiTxUOtRvWdEFJc8ZTt19Tr3GXJp7S2h7rHSW7lpLL/QfucAwqo4A3G19v9dGqcuDYjWjRDyRp5AlqvxmU9IJ8NmCICRRZvmnBSA8N3pt7p4BLCz6YX9JeW4YCgsV8J/ydtijWtaJbGOjj7783+qq8+57chjtgeJtJi5vZijLL2nZmzjc/UU7uud9/wGrL+vdRwieWhg3S4d/EeLnKW9/dYRzuC9mxwzXbuvmgNPo3PDNXmZal8xolVm9vDEjAK6tcXg6J9j7IytkmirrHEuCHCmvTvUW7LIZwUijFeTL0SDpxUClrtbZ9UQTm15fJhHFlRvuD9+avI+hBUwVYVRJWOYxdzVTvW8WZVBuXfP4EtPD6+pZGqeJvdeHcaSFV0wW8ZDIMxgE= matthewbauer@matthews-mbp.lan"

        ###
        ### Insert you ssh public keys here!
        ###
      ];

      nixiosk.networks = {
        example = "6c2734024bbc1a349e31e627c536a4d04ca5632e1ee45f33240d2c23a44f7331";

        ###
        ### Insert you network passwords here!
        ###
      };

      ###
      ### You can also change locale here for your own region and language
      ###
      nixiosk.locale = {
        lang = "en_US.UTF-8"; # localization, format is [language[_territory][.codeset][@modifier]].
        regDom = "US"; # regulatory domain; two character country code (ISO 3166-1 alpha-2)
        timeZone = "America/Chicago"; # tz database time zone
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
          nixiosk.hostName = "example-qemu-no-virtfs";
          nixiosk.hardware = "qemu-no-virtfs";
        })
      ];
    };

    nixosConfigurations.example-qemu-virtfs = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        baseConfig
        (nixiosk + /boot/qemu.nix)
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
