{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.ntp;
in {
  config = mkIf cfg.nts.enable {
    networking.firewall.extraInputRules = ''
      ip6 saddr { ${concatStringsSep "," (map(x: "${x.address}/${toString x.prefixLength}") cfg.allowedIPv6Ranges)} } tcp dport 4460 accept
    '';
  };

  imports = [
    ./acme.nix
  ];
}
