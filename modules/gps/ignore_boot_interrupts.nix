{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.stratum.gps;
in {
  config = mkIf cfg.ignore_boot_interrupts {
    systemd.services.ignore_boot_interrupts = {
      enable = true;
      wantedBy = [ "multi-user.target" "sysinit-reactivation.target" "sysinit.target" "basic.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        #!${pkgs.bash}/bin/bash
        #
        # Many GPS devices will produce data on the serial port before they're
        # initialized, confusing the u-boot and the bootloader into thinking
        # the user pressed a button to interrupt autoboot. Because we'd like
        # our device to boot without interaction, we force the bootloader to
        # not prompt the user. Because we override a generated config file, we
        # take care to "fix" this everytime this file gets overwritten.
        #
        # Ideally we would fix this properly, so we can rely on the bootloader
        # for fault-recovery.
        ${pkgs.gnugrep}/bin/grep -q '^PROMPT' /boot/extlinux/extlinux.conf ||
          ${pkgs.gnused}/bin/sed -i 's-^TIMEOUT \([0-9-]\+\)-TIMEOUT \1\nPROMPT 0\n-' /boot/extlinux/extlinux.conf
      '';
    };

    systemd.timers.ignore_boot_interrupts = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "3h";
        Unit = "ignore_boot_interrupts.service";
      };
    };

    boot.loader.timeout = 0;
  };
}
