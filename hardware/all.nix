{ modulesPath, lib, config, pkgs, ... }:

# This tries to support all hardware that we can. It’s useful for ISO
# or PXE where we don’t know what kind of machine we’ll be running on.
# The resulting files will be very big (2G+).

{

  config = lib.mkIf (builtins.elem config.nixiosk.hardware ["iso" "pxe"]) {

    hardware.enableRedistributableFirmware = true;

    boot.initrd.availableKernelModules = [
      # KMS
      "amdgpu" "i915" "nouveau"

      # QEMU support
      "virtio_net" "virtio_pci" "virtio_blk" "virtio_balloon" "virtio_console" "virtio_gpu"

      # VMware support.
      "mptspi" "vmw_balloon" "vmwgfx" "vmw_vmci" "vmw_vsock_vmci_transport" "vmxnet3" "vsock"

      # Hyper-V support.
      "hv_storvsc"
    ];

    networking.wireless.enable = true;

    systemd.services.virtualbox-vmsvga = {
      description = "VirtualBox VMSVGA Auto-Resizer";
      wantedBy = [ "multi-user.target" ];
      requires = [ "dev-vboxguest.device" ];
      after = [ "dev-vboxguest.device" ];
      unitConfig.ConditionVirtualization = "oracle";
      serviceConfig.ExecStart = "${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/VBoxClient --vmsvga";
    };

    systemd.services.qemu-guest-agent = {
      description = "Run the QEMU Guest Agent";
      unitConfig.ConditionVirtualization = "qemu";
      serviceConfig = {
        ExecStart = "${pkgs.qemu.ga}/bin/qemu-ga";
        Restart = "always";
        RestartSec = 0;
      };
    };

    environment.systemPackages = [ config.boot.kernelPackages.virtualboxGuestAdditions ];
    boot.extraModulePackages = [ config.boot.kernelPackages.virtualboxGuestAdditions ];

    hardware.firmware = [ pkgs.wireless-regdb ];

  };

}
