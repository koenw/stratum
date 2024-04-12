{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.ntp;
  super.gps = config.stratum.gps;
in {
  config = mkIf cfg.enable {
    services.chrony = {
      enable = true;
      servers = [
      ];
      enableNTS = true;
      extraFlags = [
        "-d"
      ];
      extraConfig = ''
        refclock PPS ${super.gps.pps.path} refid ${super.gps.pps.refid} trust lock ${super.gps.pps.lock}
        refclock SHM 0 refid ${super.gps.serial.refid} ${if super.gps.serial.offset != null then "offset ${super.gps.serial.offset} " else ""}trust noselect

        ${concatMapStrings (x:
        "server ${x} iburst noselect\n"
        ) cfg.servers}

        ${concatMapStrings (x:
          "allow ${x}\n")
          (map (addr:
            "${addr.address}/${toString addr.prefixLength}"
          ) cfg.allowedIPv6Ranges)
        }

        ${if cfg.nts.enable then ''
        ntsservercert ${cfg.nts.certificate}
        ntsserverkey ${cfg.nts.key}
        '' else ""}
      '';
    };

    networking.firewall.extraInputRules = ''
      ip6 saddr { ${concatStringsSep "," (map(x: "${x.address}/${toString x.prefixLength}") cfg.allowedIPv6Ranges)} } udp dport 123 accept
    '';

    systemd.services.chronyd = {
      after = [ "gpsd.service" ];
    };

  };

  imports = [
    ./nts.nix
    ./ntppool_redirects.nix
  ];
}
