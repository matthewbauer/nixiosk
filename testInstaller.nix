(import <nixpkgs/nixos> {
  system = "x86_64-linux";
  configuration = { config, ... }: {
    imports = [ (<nixpkgs> + /nixos/modules/installer/cd-dvd/installation-cd-minimal.nix) ];
    boot.kernelParams = [ "console=ttyS0" ];
    environment.sessionVariables = {
      BASALT_GIT_HOOKS = "${./git-hooks}";
    };
  };
}).config.system.build.isoImage