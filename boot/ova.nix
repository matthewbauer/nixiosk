{ modulesPath, lib, config, pkgs, ... }:

{
  imports = [ (modulesPath + "/virtualisation/virtualbox-image.nix") ];

  virtualbox.params.graphicscontroller = "vmsvga";
  virtualbox.params.usb = "off";
  virtualbox.params.usbehci = "off";

  virtualbox.vmDerivationName = "${if (config.nixiosk.localSystem.hostName or null) != null then config.nixiosk.localSystem.hostName else "nixiosk"}-ova-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
  virtualbox.vmFileName = "${if (config.nixiosk.localSystem.hostName or null) != null then config.nixiosk.localSystem.hostName else "nixiosk"}-ova-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.ova";
  virtualbox.vmName = "Nixiosk ${config.system.nixos.label} (${if (config.nixiosk.localSystem.hostName or null) != null then config.nixiosk.localSystem.hostName else "nixiosk"};${pkgs.stdenv.hostPlatform.system})";

}
