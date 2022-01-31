{
  description = "Nix-based Kiosk systems";

  inputs.nixpkgs.url = "github:matthewbauer/nixpkgs?ref=kiosk-21.05";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  nixConfig = {
    substituters = [ "https://nixiosk.cachix.org" ];
    trusted-public-keys = [ "nixiosk.cachix.org-1:A4kH9p+y9NjDWj0rhaOnv3OLIOPTbjRIsXRPEeTtiS4=" ];
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }: let
    systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);

    exampleConfigs = {
      retroPi0 = {
        hardware = "raspberryPi0";
        program = { package = "retroarch"; executable = "/bin/retroarch"; };
      };
      retroPi4 = {
        hardware = "raspberryPi4";
        program = { package = "retroarch"; executable = "/bin/retroarch"; };
      };
      retroQemu = {
        hardware = "qemu";
        program = { package = "retroarch"; executable = "/bin/retroarch"; };
      };
      cogPi0 = {
        hardware = "raspberryPi0";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogPi1 = {
        hardware = "raspberryPi1";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogPi2 = {
        hardware = "raspberryPi2";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogPi3 = {
        hardware = "raspberryPi3";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogPi4 = {
        hardware = "raspberryPi4";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogQemu = {
        hardware = "qemu";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogIso = {
        hardware = "iso";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogPxe = {
        hardware = "pxe";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      cogOva = {
        hardware = "ova";
        program = { package = "cog"; executable = "/bin/cog"; };
      };
      kodiPi2 = {
        hardware = "raspberryPi2";
        program = { package = "kodi"; executable = "/bin/kodi"; };
      };
      kodiPi3 = {
        hardware = "raspberryPi3";
        program = { package = "kodi"; executable = "/bin/kodi"; };
      };
      kodiPi4 = {
        hardware = "raspberryPi4";
        program = { package = "kodi"; executable = "/bin/kodi"; };
      };
      kodiQemu = {
        hardware = "qemu";
        program = { package = "kodi"; executable = "/bin/kodi"; };
      };
    };

    makeBootableSystem = { pkgs, custom ? null, system }:
      import ./boot { inherit pkgs custom system; };

  in {

    packages = forAllSystems (system: let
      nixpkgsFor = forAllSystems (system: import nixpkgs-unstable { inherit system; } );

    in {
      nixiosk = with nixpkgsFor.${system}; runCommand "nixiosk" {} (''
        install -m755 -D ${self}/build.sh $out/bin/nixiosk-build
        install -m755 -D ${self}/qemu.sh $out/bin/nixiosk-qemu
        install -m755 -D ${self}/deploy.sh $out/bin/nixiosk-deploy
        install -m755 -D ${self}/pixiecore.sh $out/bin/nixiosk-pixiecore
        install -m755 -D ${self}/redeploy.sh $out/bin/nixiosk-redeploy
        mkdir -p $out/share/nixiosk
        cp -r ${self}/configuration.nix ${self}/custom.nix ${self}/redeploy.nix ${self}/hardware ${self}/boot ${self}/nixpkgs $out/share/nixiosk
        install -D ${self}/README.org $out/share/doc/nixiosk/README.org
        chmod -R +w $out
        for script in $out/bin/*; do
          sed -i \
            -e "s,^#!/usr/bin/env nix-shell$,#!/usr/bin/env ${runtimeShell}," \
            -e s,^NIXIOSK=\"$PWD\"$,NIXIOSK=\"$out/share/nixiosk\", \
            $script
        done
        sed -i -e 's,^#!nix-shell -i bash -p coreutils nix jq$,PATH="${lib.makeBinPath [ coreutils nix jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-build
        sed -i -e 's,^#!nix-shell -i bash -p coreutils nix jq$,PATH="${lib.makeBinPath [ coreutils nix jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-deploy
        sed -i -e 's,^#!nix-shell -i bash -p jq openssh nix,PATH="${lib.makeBinPath [ jq openssh nix ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-redeploy
      '' + lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
        sed -i -e 's,^#!nix-shell -i bash -p nix pixiecore jq$,PATH="${lib.makeBinPath [ nix pixiecore jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-pixiecore
        sed -i -e 's,^#!nix-shell -i bash -p nix qemu jq$,PATH="${lib.makeBinPath [ nix qemu jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-qemu
      '');
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.nixiosk);

    nixosModule = import ./configuration.nix;

    nixosConfigurations = let
      system = "x86_64-linux";
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; } );

      boot = { hardware ? null, program, name, locale ? {}, ... } @ args: makeBootableSystem {
        pkgs = nixpkgsFor.${system};
        inherit system;
        custom = (builtins.removeAttrs args ["name"]) // {
          hostName = name;
          flake = self;
        };
      };
    in (builtins.mapAttrs (name: value: boot (value // { inherit name; })) exampleConfigs);

    checks = self.packages // {
      x86_64-linux = self.packages.x86_64-linux // {
        exampleQemu = (nixpkgs.lib.nixosSystem {
          modules = [
            ./boot/qemu-no-virtfs.nix
            ./configuration.nix
            ({lib, ...}: {
              nixiosk = lib.mkForce ((builtins.fromJSON (builtins.readFile ./nixiosk.json.sample)) // { hardware = "qemu-no-virtfs"; });
              nixpkgs.localSystem = { system = "x86_64-linux"; };
            })
          ];
        }).config.system.build.qcow2;
      };
    };

    templates.kodiKiosk = {
      description = "Kodi Kiosk on multiple platforms";
      path = ./template;
    };
    defaultTemplate = self.templates.kodiKiosk;

    hydraJobs = self.checks.x86_64-linux
      // builtins.mapAttrs (_: system: system.config.system.build.toplevel) self.nixosConfigurations;

    devShell = forAllSystems (system: let
      nixpkgsFor = forAllSystems (system: import nixpkgs-unstable { inherit system; } );
    in with nixpkgsFor.${system}; stdenv.mkDerivation {
      name = "nixiosk";

      nativeBuildInputs = [
        (writeShellScriptBin "update-cache" ''
          PATH=$PATH''${PATH:+:}${lib.makeBinPath [ cachix nix findutils ]}
          ( nix-build -E '(import ./.).hydraJobs' ;
            nix-instantiate -E '(import ./.).hydraJobs' | xargs nix-store -qR --include-outputs | grep -v '\.drv$' ;
            ) | cachix push nixiosk
        '')
      ];
    });

  };

}
