{
  description = "Example system";

  inputs.nixiosk.url = "github:matthewbauer/nixiosk";
  inputs.nixpkgs.url = "github:matthewbauer/nixpkgs?ref=kiosk6";

  outputs = { self, nixiosk, nixpkgs }: let
    systems = [ "x86_64-linux" ];
    forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; } );
  in {
    packages = forAllSystems (system: let
      commonModule = ({...}: {
        nixpkgs.localSystem = { inherit system; };
        nixiosk.flake = self;
        imports = [ (nixiosk + /boot/flake.nix) ];
      });
    in {
      sdImage = (nixpkgs.lib.nixosSystem {
        modules = [
          ({...}: { nixiosk.hardware = "raspberryPi4"; })
          commonModule
          self.nixosConfigurations.example
          (nixiosk + /boot/raspberrypi.nix)
        ];
      }).config.system.build.sdImage;
      qcow2 = (nixpkgs.lib.nixosSystem {
        modules = [
          ({...}: { nixiosk.hardware = "qemu-no-virtfs"; })
          commonModule
          self.nixosConfigurations.example
          (nixiosk + /boot/qemu-no-virtfs.nix)
        ];
      }).config.system.build.qcow2;
      isoImage = (nixpkgs.lib.nixosSystem {
        modules = [
          ({...}: { nixiosk.hardware = "iso"; })
          commonModule
          self.nixosConfigurations.example
          (nixiosk + /boot/iso.nix)
        ];
      }).config.system.build.isoImage;
      virtualBoxOVA = (nixpkgs.lib.nixosSystem {
        modules = [
          ({...}: { nixiosk.hardware = "ova"; })
          commonModule
          self.nixosConfigurations.example
          (nixiosk + /boot/ova.nix)
        ];
      }).config.system.build.virtualBoxOVA;
    });

    nixosConfigurations.example = { pkgs, ... }: {
      imports = [ nixiosk.nixosModule ];
      nixiosk.hostName = "example";
      nixiosk.locale = {
        lang = "en_US.UTF-8";
        regDom = "US";
        timeZone = "America/Chicago";
      };
      nixiosk.program = {
        executable = "/bin/kodi";
        package = pkgs.kodi;
      };
      nixiosk.raspberryPi.firmwareConfig = ''
        dtparam=audio=on
      '';
    };

  };

}
