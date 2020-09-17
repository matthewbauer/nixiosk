{
  description = "Example system";

  inputs.nixiosk.url = "github:matthewbauer/nixiosk";
  inputs.nixpkgs.url = "github:matthewbauer/nixpkgs?ref=kiosk6";

  outputs = { self, nixiosk, nixpkgs }: let
    systems = [ "x86_64-linux" ];
    forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; } );
  in {
    defaultPackage = forAllSystems (system: self.packages.${system}.sdImage);

    packages = forAllSystems (system: {
      sdImage = (nixpkgs.lib.nixosSystem {
        modules = [
          ({...}: { nixiosk.hardware = "raspberryPi3"; })
          ({...}: { nixpkgs.localSystem = { inherit system; }; })
          self.nixosModule
          (nixiosk + /boot/raspberrypi.nix)
        ];
      }).config.system.build.sdImage;
    });

    nixosModule = { pkgs, ... }: {
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
