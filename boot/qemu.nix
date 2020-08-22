{ modulesPath, lib, config, pkgs, ... }: {

  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  fileSystems = lib.mkOverride 5 {
    "/".device = "/dev/vda";
    "/nix/store" = {
      device = "store";
      fsType = "9p";
      options = [ "trans=virtio" "version=9p2000.L" "cache=loose" ];
      neededForBoot = true;
    };
  };

  virtualisation.writableStore = false;

}
