{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.gps;
in {
  config = {
    systemd.services."serial-getty@${baseNameOf cfg.serial.path}".enable = false;

    services.gpsd = {
      enable = true;
      nowait = true;
      readonly = false;
      listenany = false;
      debugLevel = 3;
      devices = [
        cfg.serial.path
        cfg.pps.path
      ];
    };

    environment.systemPackages = with pkgs; [
      gpsd
      pps-tools
      jq
    ];
  };

  imports = [
    ./gpsd_watchdog.nix
    ./ignore_boot_interrupts.nix
  ];
}
