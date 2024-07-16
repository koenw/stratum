{ klokkijker, ... }:
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.monitoring;

  ntp = config.stratum.ntp;
in {
  options.stratum.monitoring = {
    klokkijker = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NTP monitorint with prometheus export";
      };

      interval = mkOption {
        type = types.int;
        default = 5;
        description = "Interval in seconds between NTP request salvo's";
      };

      count = mkOption {
        type = types.int;
        default = 1;
        description = "Amount of NTP request to send to each server every salvo";
      };

      fqdn = mkOption {
        type = types.str;
        default = strings.concatStrings [ config.networking.hostName "." config.networking.domain ];
        example = "time.example.com";
        description = (mdDoc "Our fqdn that will be monitored, in addition to `stratum.ntp.servers`.");
      };
    };

    grafana = {
      enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = (mdDoc "Enable local grafana instance (with tls + acme)");
      };

      domain = mkOption {
        type = types.str;
        default = strings.concatStrings [ "grafana" "." cfg.klokkijker.fqdn ];
        example = "grafana.time.example.com";
        description = (mdDoc "The domain that grafana will be listening on. This domain should be globally resolvable for ACME and point to us.");
      };
    };
  };

  config = {

    environment.systemPackages = [
      klokkijker.packages."${pkgs.system}".default
    ];

    systemd.services.klokkijker = mkIf cfg.klokkijker.enable {
      enable = true;
      after = [ "network.target" ];
      requires = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${klokkijker.packages."${pkgs.system}".default}/bin/klokkijker monitor --interval ${toString cfg.klokkijker.interval} --count ${toString cfg.klokkijker.count} ${cfg.klokkijker.fqdn} ${concatStringsSep " " ntp.servers}";
        Restart = "always";
      };
    };

    services.prometheus = {
      enable = true;
      port = 9001;
      scrapeConfigs = [
        {
          job_name = "klokkijker";
          scrape_interval = "${toString cfg.klokkijker.interval}s";
          static_configs = [
            {
              targets = [ "127.0.0.1:8123" ];
            }
          ];
        }
      ];
    };

    services.grafana = mkIf cfg.grafana.enable {
      enable = true;
      settings.server = {
        http_port = 2342;
        http_addr = "127.0.0.1";
        domain = cfg.grafana.domain;
        serve_from_sub_path = false;
        root_url = "https://${cfg.grafana.domain}/";
        enable_gzip = true;
      };
      settings.auth = {
        "anonymous.enabled" = false;
        "anonymous.org_name" = "anonymous";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
    };

    services.nginx = mkIf cfg.grafana.enable {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${cfg.grafana.domain}" = {
        addSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
}
