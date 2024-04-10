{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.stratum.i2c-rtc;
in {

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
