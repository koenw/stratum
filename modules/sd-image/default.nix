{ config, lib, pkgs, nixos, modulesPath, ... }:
with lib;
{
  imports = [
    # Minimal set of programs (e.g. pkgs.vim and pkgs.parted)
    (modulesPath + "/profiles/base.nix")

    # (Try to) populate /etc/nixos/configuration.nix
    (modulesPath + "/profiles/clone-config.nix")

    # Include a copy of nixpkgs to nixos-install works out of the box
    (modulesPath + "/installer/cd-dvd/channel.nix")

		# Build an bootable sdImage in config.system.build.sdImage
    (modulesPath + "/installer/sd-card/sd-image.nix")

    # Keep image size & attack surface fit to our purpose
    ./minimize.nix
    ./hardening.nix
  ];

  config = {
    documentation.enable = mkDefault true;

    users.users.stratum = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialHashedPassword = "";
    };

    services.getty.helpLine = ''

      The 'stratum' account has an empty password.

      Use `sudo` to become root.

      To login over ssh add your public key to /home/stratum/.ssh/authorized_keys:

        mkdir -m 700 ~/.ssh
        curl https://github.com/<username>.keys >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys

      To make changes to the system configuration, edit
      /etc/nixos/configuration.nix and run `nixos-rebuild switch`. See the
      NixOS manual for details.
    '';

    environment.systemPackages = with pkgs; [
      curl
    ];

    # Remove the warning about unset mail since we're not moving software raid
    # anyway.
    boot.swraid.enable = false;

    # Allow nix-copy to the live system
    nix.settings.trusted-users = [ "root" "@wheel" ];

    system.nixos.label = "Stratum";

    sdImage = {
      firmwarePartitionName = "FIRMWARE";
      compressImage = false;
      populateFirmwareCommands = let
        configTxt = pkgs.writeText "config.txt" ''
          [pi3]
          kernel=u-boot-rpi3.bin

          [pi02]
          kernel=u-boot-rpi3.bin

          [pi4]
          kernel=u-boot-rpi4.bin
          enable_gic=1
          armstub=armstub8-gic.bin

          # Otherwise the resolution will be weird in most cases, compared to
          # what the pi3 firmware does by default.
          disable_overscan=1

          # Supported in newer board revisions
          arm_boost=1

          [cm4]
          # Enable host mode on the 2711 built-in XHCI USB controller.
          # This line should be removed if the legacy DWC2 controller is required
          # (e.g. for USB device mode) or if USB support is not required.
          otg_mode=1

          [all]
          # Boot in 64-bit mode.
          arm_64bit=1

          # Many GPS devices transmit signals over UART, making u-boot pause
          # thinking there was a keyboard interrupt. To enable the device to be
          # able to boot without user interaction, we disable uart for u-boot.
          enable_uart=0

          # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
          # when attempting to show low-voltage or overtemperature warnings.
          avoid_warnings=1

          # Custom overlays to facilitate GPS timekeeping modules
          dtoverlay=pps-gpio,gpiopin=18
          dtoverlay=disable-bt
        '';
      in ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)

        # Add the config
        cp ${configTxt} firmware/config.txt

        # Add pi3 specific files
        cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin firmware/u-boot-rpi3.bin

        # Add pi4 specific files
        cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
        cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-400.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4s.dtb firmware/

        # (Experimental) Copy overlays
        mkdir firmware/overlays
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/disable-bt.dtbo firmware/overlays/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/pps-gpio.dtbo firmware/overlays/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/disable-wifi.dtbo firmware/overlays/
      '';

      populateRootCommands = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot

        # Somehow `disabledModules` doesn't do what I what (doesn't seem to do
        # anything) so I'm solving it in this hacky way.
        # TODO: Properly parameterize extlinux module
        ${pkgs.gnused}/bin/sed -i 's-^TIMEOUT \([0-9-]\+\)-TIMEOUT \1\nPROMPT 0\n-' ./files/boot/extlinux/extlinux.conf
      '';
    };
  };
}
