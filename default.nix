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
    ./modules/options.nix
    ./modules/hardware/raspberry-pi.nix
    ./modules/hardware/i2c-rtc.nix
    ./modules/gps
    ./modules/ntp
    ./modules/openssh.nix
  ];
}
