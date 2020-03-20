{ modulesPath, lib, config, ... }:

{
  imports = [ (modulesPath + "/virtualisation/virtualbox-image.nix") ];

  virtualbox.params.graphicscontroller = "vmsvga";
  virtualbox.params.usb = "off";
  virtualbox.params.usbehci = "off";

  # systemd.services.virtualbox-vmsvga =
  #   { description = "VirtualBox VMSVGA Auto-Resizer";
  #     wantedBy = [ "multi-user.target" ];
  #     requires = [ "dev-vboxguest.device" ];
  #     after = [ "dev-vboxguest.device" ];
  #     unitConfig.ConditionVirtualization = "oracle";
  #     serviceConfig.ExecStart = "@${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --vmsvga";
  #   };

}
