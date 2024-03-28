{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.stratum.i2c-rtc;
in {
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

  config = mkIf cfg.enable {
    hardware.i2c.enable = true;

    boot.kernelModules = [
      "rtc-ds1307"
    ];

    environment.systemPackages = with pkgs; [
      i2c-tools
    ];

    systemd.services.add-i2c-rtc = {
      description = "";
      wantedBy = [ "time-sync.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        # Inform the kernel about the (${cfg.model}) i2c RTC
        echo "${cfg.model}" "${cfg.address}" > "/sys/class/i2c-adapter/i2c-${toString cfg.bus}/new_device"
      '';
    };
  };
}
