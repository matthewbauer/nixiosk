{...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "console=ttyS0" ];
  fileSystems."/" = { device = "/dev/sda2"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/sda1"; fsType = "vfat"; };
  users.users.root.hashedPassword = "$6$fpizjqA4j$xYuPmLI1c6Z7DcDIyDaPAW4nGL8KN2HhuuAB8avyd5D2FvuCbZG9zldi4OZwogMiOReZNWq1FkO3l3i1kYinF/";
}
