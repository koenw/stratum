{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum;
in {
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

    environment.etc."stratum/flake.nix".source = ./flake.nix.example;
    environment.etc."stratum/README.md".source = ./README.md;
    environment.etc."stratum/options.md".source = ./docs/options.md;

    system.stateVersion = mkDefault "24.05";
  };

  imports = [
    ./modules/options.nix
    ./modules/hardware/raspberry-pi.nix
    ./modules/hardware/i2c-rtc.nix
    ./modules/gps
    ./modules/ntp
    ./modules/openssh.nix
  ];
}
