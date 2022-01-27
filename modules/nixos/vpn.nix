{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.vpn;
in
{
  options.services.role.vpn = {
    enable = mkEnableOption "Whether to setup openvpn on a node or not";
  };

  config = mkIf cfg.enable
    {
      environment.systemPackages = [
        pkgs.openconnect
        pkgs.openresolv
        pkgs.openvpn
      ];

      services.resolved = {
        enable = true;
        fallbackDns = [ "8.8.8.8" "2001:4860:4860::8844" ];
      };

      services.openvpn.servers = {
        fremont = {
          config = '' config /home/mitch/src/wrk/github.com/rancherlabs/fremont/VPN/Ranch01/ranch01-fremont-udp.ovpn '';
          up = "${pkgs.openvpn}/libexec/update-systemd-resolved";
          down = "${pkgs.openvpn}/libexec/update-systemd-resolved";
        };
      };
    };
}
