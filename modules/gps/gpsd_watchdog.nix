{config, pkgs, lib, ... }:
with lib;
let
  cfg = config.stratum.gps;
in {
  config = mkIf cfg.gpsd_watchdog.enable {
    systemd.services.gpsd_watchdog = {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        #!${pkgs.bash}/bin/bash
        #
        # It can happen, with some GPS modules more than with others, that for
        # some reason the serial line gets overrun and gpsd loses the
        # connection. This causes the need for the serial device to be
        # re-initialized again, however, because gpsd drops root priviliges
        # after initialization it is unable to do so. The only fix is to
        # restart gpsd.
        #
        # The proper solution would be to fix the issue of why your GPS
        # module resets (faulty cabling, faulty module, another device
        # using the same GPIO pins, etc).
        #
        # This script will monitor chrony & gpsd and restart gpsd when it
        # detects that gpsd hasn't been forwarding the NMEA and PPS
        # signals for a while.
        set -x

        last_rx=$(
          ${pkgs.chrony}/bin/chronyc -c sources |
          # $1 == "#" -> Local clock source
          # $6 != 0   -> Clock has been reached succesfully in the past
          ${pkgs.gawk}/bin/awk -F, '{ if ($1 == "#" && $6 != 0) {print $7} }' |
          sort -n |
          tail -n1
        )

        if echo -n "$last_rx" |${pkgs.gnugrep}/bin/grep -q '[^0-9]'; then
          echo "Non-integer value for LastRx, chrony is probably still starting/calibrating"
          exit 0
        elif test -z "$last_rx" || test "$last_rx" -gt 60; then
          echo "Restarting gpsd (LastRx=$last_rx)"
          systemctl restart gpsd
        fi
      '';
    };

    systemd.timers.gpsd_watchdog = {
      wantedBy = [ "timers.target" "gpsd.service" ];
      timerConfig = {
        OnBootSec = "10m";
        OnUnitActiveSec = "2m";
        Unit = "gpsd_watchdog.service";
      };
    };
  };
}
