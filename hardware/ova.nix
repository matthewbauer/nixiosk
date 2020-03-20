{ lib, pkgs, config, ... }: {

  config = lib.mkIf (builtins.elem config.nixiosk.hardware ["ova"]) {

    boot.loader.grub.fsIdentifier = "provided";
    users.users.kiosk.extraGroups = [ "vboxsf" ];
    powerManagement.enable = false;

    swapDevices = [{
      device = "/var/swap";
      size = 2048;
    }];

    virtualisation.virtualbox.guest.enable = true;

    boot.growPartition = true;
    boot.loader.grub.device = "/dev/sda";

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };

  };

}
