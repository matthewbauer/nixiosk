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

    nixpkgs.overlays = [(self: super: {
      # Restrict drivers built by mesa to just the ones we need This
      # reduces the install size a bit.
      mesa = (super.mesa.override {
        vulkanDrivers = [];
        driDrivers = [];
        galliumDrivers = ["svga" "swrast"];
        enableRadv = false;
        withValgrind = false;
        enableOSMesa = false;
        enableGalliumNine = false;
      }).overrideAttrs (o: {
        mesonFlags = (o.mesonFlags or []) ++ ["-Dglx=disabled"];
      });
    })];

  };

}
