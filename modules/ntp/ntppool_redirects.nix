{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.ntp.ntppool.redirects;
in {
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 ];

    services.nginx = {
      enable = true;
      virtualHosts = {
        # Since some people will visit the address of their NTP server in their
        # browser, we direct to www.ntppool.org as requested at
        # https://www.ntppool.org/en/join.html.
        "pool.ntp.org" = {
          serverAliases = [
            "*.pool.ntp.org"
            "*.ntppool.org"
          ];
          # We can't use 'globalRedirect' here because it assumes the target
          # doesn't support SSL if we ourself don't.
          extraConfig = ''
            location / {
              return 301 https://www.ntppool.org/;
            }
          '';
        };
      };
    };
  };
}
