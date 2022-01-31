{ lib, pkgs, config, ... }: {

  config = lib.mkIf (builtins.elem config.nixiosk.hardware ["ova"]) {

    boot.loader.grub.fsIdentifier = "provided";
    users.users.kiosk.extraGroups = [ "vboxsf" ];

    virtualisation.virtualbox.guest.enable = true;

    boot.growPartition = true;
    boot.loader.grub.device = "/dev/sda";

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };

    boot.initrd.availableKernelModules = [ "vmwgfx" ];

    systemd.services.virtualbox-vmsvga = {
      description = "VirtualBox VMSVGA Auto-Resizer";
      wantedBy = [ "multi-user.target" ];
      requires = [ "dev-vboxguest.device" ];
      after = [ "dev-vboxguest.device" ];
      unitConfig.ConditionVirtualization = "oracle";
      serviceConfig.ExecStart = "${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --vmsvga";
    };

  };

}
