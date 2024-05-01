{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.ntp;

  gps = config.stratum.gps;

  gpsRefclockConfig = ''
    refclock PPS ${gps.pps.path} refid ${gps.pps.refid} trust lock ${gps.pps.lock}
    refclock SHM 0 refid ${gps.serial.refid} ${if gps.serial.offset != null then "offset ${gps.serial.offset} " else ""}trust noselect
  '';
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
        ${if gps.enable then gpsRefclockConfig else ""}

        ${concatMapStrings
         (x: "server ${x} iburst ${if gps.enable then "noselect" else ""}\n")
         cfg.servers}

        ${concatMapStrings
          (x: "allow ${x}\n")
          (map
            (addr: "${addr.address}/${toString addr.prefixLength}")
            (cfg.allowedIPv6Ranges ++ cfg.allowedIPv4Ranges)
          )
        }

        ${if cfg.nts.enable then ''
        ntsservercert ${cfg.nts.certificate}
        ntsserverkey ${cfg.nts.key}
        '' else ""}
      '';
    };

    networking.firewall.extraInputRules = ''
      ip6 saddr { ${concatStringsSep "," (map(x: "${x.address}/${toString x.prefixLength}") cfg.allowedIPv6Ranges)} } udp dport 123 accept
      ip saddr { ${concatStringsSep "," (map(x: "${x.address}/${toString x.prefixLength}") cfg.allowedIPv4Ranges)} } udp dport 123 accept
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
