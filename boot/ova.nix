{ modulesPath, lib, ... }:

{
  imports = [ (modulesPath + "/virtualisation/virtualbox-image.nix") ];

  boot.loader.grub.fsIdentifier = "provided";
  users.users.kiosk.extraGroups = [ "vboxsf" ];
  services.xserver.videoDrivers = lib.mkOverride 40 [ "virtualbox" "vmware" "cirrus" "vesa" "modesetting" ];
  powerManagement.enable = false;
}
