{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.ntp;
  super.gps = config.stratum.gps;
in {
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
      '';
    };

    networking.firewall.extraInputRules = ''
      ip6 saddr { ${concatStringsSep "," (map(x: "${x.address}/${toString x.prefixLength}") cfg.allowedIPv6Ranges)} } udp dport 123 accept
    '';

    systemd.services.chronyd = {
      after = [ "gpsd.service" ];
    };
  };
}
