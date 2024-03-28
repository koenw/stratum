{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum;

  addrOpts = v:
    assert v == 4 || v == 6;
    {
      options = {
        address = mkOption {
          type = types.str;
          description = lib.mdDoc ''
            IPv${toString v} address of the interface. Leave empty to configure the
            interface using DHCP.
          '';
        };

        prefixLength = mkOption {
          type = types.addCheck types.int
            (n: n >= 0 && n <= (if v == 4 then 32 else 128));
          description = lib.mdDoc ''
            Subnet mask of the interface, specified as the number of
            bits in the prefix (`${if v == 4 then "24" else "64"}`).
          '';
        };
      };
    };
in {
  options.stratum = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc "Enable Stratum 1 NTP server";
    };

    gps = {
      serial = {
        path = mkOption {
          default = "/dev/ttyS1";
          type = types.str;
          description = mdDoc "GPS Serial device";
        };
        offset = mkOption {
          default = null;
          type = types.nullOr types.str;
        };
        refid = mkOption {
          default = "NMEA";
        };
      };

      ignore_boot_interrupts = mkOption {
        default = true;
        type = types.bool;
        description = mdDoc ''
          Many GPS devices will produce data on the serial port before they're
          initialized, confusing the u-boot and the bootloader into thinking the
          user pressed a button to interrupt autoboot. Because we'd like our
          device to boot without interaction, we force the bootloader to not
          prompt the user. Because we override a generated config file, we take
          care to "fix" this everytime this file gets overwritten.

          Ideally we would fix this properly, so we can rely on the bootloader
          for fault-recovery.
        '';
      };

      pps = {
        path = mkOption {
          default = "/dev/pps0";
          type = types.str;
          description = mdDoc "GPS PPS device";
        };
        lock = mkOption {
          default = cfg.gps.serial.refid;
        };
        refid = mkOption {
          default = "PPS";
        };
      };

      gpsd_watchdog.enable = mkOption {
        default = true;
        type = types.bool;
        description = mdDoc ''
          It can happen, with some GPS modules more than with
          others, that for some reason the serial line gets overrun and
          gpsd loses the connection. This causes the need for the serial
          device to be re-initialized again. However, because gpsd drops
          root priviliges after initialization it is unable to do so. The
          only fix is to restart gpsd.

          The proper solution would be to fix the issue of why your GPS
          module resets (faulty cabling, faulty module, another device
          using the same GPIO pins, etc).

          This will enable a watchdog that will monitor chrony & gpsd and restart
          gpsd when it detects that gpsd hasn't been forwarding the NMEA and PPS
          signals for a while.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.enableEmergencyMode = mkDefault false;

    time.timeZone = mkDefault "UTC";

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    networking.nftables.enable = true;

    environment.systemPackages = with pkgs; [
      picocom minicom
      pps-tools
      dtc
    ];

    system.stateVersion = "24.05";
  };

  imports = [
    ./modules/hardware/raspberry-pi.nix
    ./modules/hardware/i2c-rtc.nix
    ./modules/gps
    ./modules/ntp
    ./modules/openssh.nix
  ];
}
