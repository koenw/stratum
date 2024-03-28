{ config, lib, pkgs, ... }:
with lib;
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    # Just reboot on panic
    kernelParams = [ "panic=1" "boot.panic_on_fail" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/mnt" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };

  # Write as little as possible to the SD-cards
  swapDevices = [ ];
}
