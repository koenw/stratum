{
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

  options.stratum.ntp = {
    enable = mkOption {
      default = config.stratum.enable;
      type = types.bool;
      description = mdDoc "Enable (chrony) NTP Server";
    };

    allowedIPv6Ranges = mkOption {
      default = [ { address = "fe80::"; prefixLength = 10; } ];
      example = [
        { address = "fe80::"; prefixLength = 10; }
        { address = "2001:db8::"; prefixLength = 32; }
      ];
      description = mdDoc ''
        IPv6 Ranges that will be allowed to query our NTP
        server. This will open the firewall for these ranges
        and configure the ACL's in chrony.
      '';
    };

    servers = mkOption {
      default = [
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
        "4.nixos.pool.ntp.org"
      ];
      description = mdDoc ''
        These servers are strictly optional and not used by chrony to adjust
        the clock. Instead they can be monitored (e.g. with `chronyc sources`)
        to get a sense of our time compared to the community.
      '';
    };
  };

  options.stratum.i2c-rtc = {
    enable = mkEnableOption (mdDoc "I2C Real Time Clock support");

    model = mkOption {
      type = types.str;
      default = "ds3231";
      example = "ds1307";
      description = ''
      This will be passed to the kernel driver. If your model isn't directly known by the kernel, you might get lucky using the "ds1307" model string as fallback.
      '';
    };

    address = mkOption {
      type = types.str;
      default = "0x68";
      description = ''
      Detect with `i2cdetect <bus>`
      '';
    };

    bus = mkOption {
      type = types.ints.positive;
      default = 3;
      description = ''
      '';
    };
  };

}
