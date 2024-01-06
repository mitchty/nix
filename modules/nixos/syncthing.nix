{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.syncthing;
in
{
  options.services.role.syncthing = {
    enable = mkEnableOption "Setup as a syncthing enabled system";
  };

  config = mkIf cfg.enable {
    # https://docs.syncthing.net/users/firewall.html
    networking.firewall.allowedTCPPorts = [
      22000
    ];
    networking.firewall.allowedUDPPortRanges = [
      { from = 21027; to = 21027; }
      { from = 22000; to = 22000; }
    ];
  };
}
