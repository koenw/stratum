{ config, lib, ... }:
with lib;
{
  environment.noXlibs = mkDefault true;

  environment.defaultPackages = [ ];

  # Prevent pulling in perl, and we're not using containers anyway (we *are*
  # using cgroups/namespaces though, don't need nixos-containers for that).
  boot.enableContainers = mkDefault false;

  documentation.info.enable = mkDefault false;

  programs.less.lessopen = mkDefault null;

  services.udisks2.enable = mkDefault false;

  xdg.autostart.enable = mkDefault false;
  xdg.icons.enable = mkDefault false;
  xdg.mime.enable = mkDefault false;
  xdg.sounds.enable = mkDefault false;
}
