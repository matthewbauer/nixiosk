{ modulesPath, lib, config, pkgs, ... }:

{
  imports = [ (modulesPath + "/virtualisation/virtualbox-image.nix") ];

  virtualbox.params.graphicscontroller = "vmsvga";
  virtualbox.params.usb = "off";
  virtualbox.params.usbehci = "off";

  virtualbox.vmDerivationName = "${config.nixiosk.hostName}-ova-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
  virtualbox.vmFileName = "${config.nixiosk.hostName}-${pkgs.stdenv.hostPlatform.system}.ova";
  virtualbox.vmName = "${config.nixiosk.hostName} ${config.system.nixos.label} (${pkgs.stdenv.hostPlatform.system})";

}
