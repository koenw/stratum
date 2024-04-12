{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.ntp.nts.acme;
  super = config.stratum.ntp;
in {
  config = mkIf cfg.enable {
    security.acme = {
      certs."${cfg.fqdn}" = {
        reloadServices = [
          "chronyd.service"
        ];
        email = cfg.email;

        postRun = ''
          systemctl start copyNTSCertificate.service
        '';
      };
    };

    # For some reason chrony returned a 'permission denied' when opening
    # /var/lib/acme/<domain>/key.pem, even if the 'chrony' user had read
    # permissions via auxiliary groups. Since nginx needs read permissions too
    # and I didn't want to make 'nginx' a member of the 'chrony' group, I've
    # opted to just copy the key & certificate to chrony's dir.
    systemd.services.copyNTSCertificate = {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        # Copy ACME key and certificate to chrony's directory
        #
        # For some reason chrony returns a 'permission denied' when opening
        # /var/lib/acme/<domain>/key.pem, even if the 'chrony' user has read
        # permissions via auxiliary groups. Since nginx needs read permissions
        # too and I don't want to make 'nginx' a member of the 'chrony' group,
        # I've opted to just copy the key & certificate to chrony's dir.
        #
        # This service is automatically triggered every time the certificate is
        # updated or before chrony is started.
        for f in key.pem fullchain.pem; do
          ${pkgs.coreutils}/bin/cp "${config.security.acme.certs."${cfg.fqdn}".directory}/$f" "${config.services.chrony.directory}/"
          ${pkgs.coreutils}/bin/chown chrony:chrony "${config.services.chrony.directory}/$f"
        done
      '';
    };

    systemd.services.chronyd = {
      wants = [ "copyNTSCertificate.service" ];
    };

    networking.firewall.allowedTCPPorts = [ 80 ];

    services.nginx = {
      enable = true;
      virtualHosts = {
        "tik.koenw.dev" = {
          enableACME = true;
          extraConfig = mkIf super.ntppool.redirects.enable ''
            location / {
              return 301 https://www.ntppool.org/;
            }
          '';
        };
      };
    };
  };
}
