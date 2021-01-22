{
  description = "Nix-based Kiosk systems";

  inputs.nixpkgs.url = "github:matthewbauer/nixpkgs?ref=kiosk7";

  outputs = { self, nixpkgs }: let
    systems = [ "x86_64-linux" ];
    forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);

    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; } );

    exampleConfigs = {
      retroPi0 = {
        hardware = "raspberryPi0";
        program = { package = "retroarch"; executable = "/bin/retroarch"; };
        locale.timeZone = "America/New_York";
      };
      retroPi4 = {
        hardware = "raspberryPi4";
        program = { package = "retroarch"; executable = "/bin/retroarch"; };
        locale.timeZone = "America/New_York";
      };
      retroQemu = {
        hardware = "qemu";
        program = { package = "retroarch"; executable = "/bin/retroarch"; };
      };
      cogPi0 = {
        hardware = "raspberryPi0";
        program = { package = "cog"; executable = "/bin/cog"; };
        locale.timeZone = "America/New_York";
      };
      cogPi1 = {
        hardware = "raspberryPi1";
        program = { package = "cog"; executable = "/bin/cog"; };
        locale.timeZone = "America/New_York";
      };
      cogPi2 = {
        hardware = "raspberryPi2";
        program = { package = "cog"; executable = "/bin/cog"; };
        locale.timeZone = "America/New_York";
      };
      cogPi3 = {
        hardware = "raspberryPi3";
        program = { package = "cog"; executable = "/bin/cog"; };
        locale.timeZone = "America/New_York";
      };
      cogPi4 = {
        hardware = "raspberryPi4";
        program = { package = "cog"; executable = "/bin/cog"; };
        locale.timeZone = "America/New_York";
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
        locale.timeZone = "America/New_York";
      };
      kodiPi3 = {
        hardware = "raspberryPi3";
        program = { package = "kodi"; executable = "/bin/kodi"; };
        locale.timeZone = "America/New_York";
      };
      kodiPi4 = {
        hardware = "raspberryPi4";
        program = { package = "kodi"; executable = "/bin/kodi"; };
        locale.timeZone = "America/New_York";
      };
      kodiQemu = {
        hardware = "qemu";
        program = { package = "kodi"; executable = "/bin/kodi"; };
      };
    };

  in {

    packages = forAllSystems (system: {
      nixiosk = with nixpkgsFor.${system}; runCommand "nixiosk" {} ''
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
        sed -i -e 's,^#!nix-shell -i bash -p coreutils nixUnstable jq$,PATH="${lib.makeBinPath [ coreutils nixUnstable jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-build
        sed -i -e 's,^#!nix-shell -i bash -p nixUnstable qemu jq$,PATH="${lib.makeBinPath [ nixUnstable qemu jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-qemu
        sed -i -e 's,^#!nix-shell -i bash -p coreutils nixUnstable jq$,PATH="${lib.makeBinPath [ coreutils nixUnstable jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-deploy
        sed -i -e 's,^#!nix-shell -i bash -p nixUnstable pixiecore jq$,PATH="${lib.makeBinPath [ nixUnstable pixiecore jq ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-pixiecore
        sed -i -e 's,^#!nix-shell -i bash -p jq openssh nixUnstable$,PATH="${lib.makeBinPath [ jq openssh nixUnstable ]}''${PATH:+:}$PATH",' $out/bin/nixiosk-redeploy
      '';
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.nixiosk);

    lib.makeBootableSystem = { pkgs, custom ? null, system }:
      import ./boot { inherit pkgs custom system; };

    nixosModule = import ./configuration.nix;

    nixosConfigurations = let
      system = "x86_64-linux";
      boot = { hardware ? null, program, name, locale ? {} }: self.lib.makeBootableSystem {
        pkgs = nixpkgsFor.${system};
        inherit system;
        custom = {
          inherit hardware program locale;
          hostName = name;
        };
      };
    in (builtins.mapAttrs (name: value: boot (value // { inherit name; })) exampleConfigs);

    checks = forAllSystems (system: {
      inherit (self.packages.${system}) nixiosk;

      exampleQemu = (nixpkgs.lib.nixosSystem {
        modules = [
          ./boot/qemu-no-virtfs.nix
          ./configuration.nix
          ({lib, ...}: {
            nixiosk = lib.mkForce ((builtins.fromJSON (builtins.readFile ./nixiosk.json.sample)) // { hardware = "qemu-no-virtfs"; });
            nixpkgs.localSystem = { inherit system; };
          })
        ];
      }).config.system.build.qcow2;
    });

    nixConfig.substituters = [ "https://nixiosk.cachix.org" ];

    templates.kodiKiosk.description = "Kodi Kiosk on multiple platforms";
    templates.kodiKiosk.path = ./template;
    defaultTemplate = self.templates.kodiKiosk;

    hydraJobs = self.checks.x86_64-linux
      // builtins.mapAttrs (name: value: value.config.system.build.toplevel) self.nixosConfigurations;

  };
}
