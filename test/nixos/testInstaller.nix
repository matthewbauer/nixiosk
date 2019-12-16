(import <nixpkgs/nixos> {
  system = "x86_64-linux";
  configuration = { config, pkgs, lib, ... }: {
    imports = [
      (<nixpkgs> + /nixos/modules/installer/cd-dvd/installation-cd-minimal.nix)
    ];
    boot.kernelParams = [ "console=ttyS0" ];
    environment.sessionVariables = {
      # This is just to ensure it gets included in the installer's nix store so we don't need to access the network
      TARGET_PIN = builtins.toString (import <nixpkgs/nixos> { configuration = import ./testTarget.nix; }).system;
    };
    isoImage.includeSystemBuildDependencies = true;
    environment.systemPackages = with pkgs; [
      git
      gitAndTools.git-subrepo
    ];
    nix.binaryCaches = lib.mkForce [ "auto?trusted=1" ];
    nix.extraOptions = ''
      fallback = true
    '';
  };
}).config.system.build.isoImage
