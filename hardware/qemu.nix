{ lib, pkgs, config, ... }: {

  config = lib.mkIf (builtins.elem config.nixiosk.hardware ["qemu" "qemu-no-virtfs"]) {

    boot.loader.grub.device = "/dev/vda";

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
        autoResize = true;
      };
    };

    networking.usePredictableInterfaceNames = false;
    services.qemuGuest.enable = true;
    services.timesyncd.enable = false;

    boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "9p" "9pnet_virtio" ];
    boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" "virtio_gpu" ];

    boot.initrd.postDeviceCommands = ''
      # Set the system time from the hardware clock to work around a
      # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
      # to the *boot time* of the host).
      hwclock -s
    '';

    security.rngd.enable = false;

    powerManagement.enable = false;

    hardware.firmware = [ pkgs.wireless-regdb ];

  };

}
