{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.grafana;
in
{
  options.services.role.grafana = {
    enable = mkEnableOption "Setup as a grafana server";
    cname = mkOption {
      type = types.str;
      default = "grafana.home.arpa";
      description = "Internal dns domain to use for the loki cname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.129";
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "enp142s0";
      description = "interface to add vip to";
    };
  };

  config = mkIf cfg.enable rec {
    networking = {
      interfaces = {
        "${cfg.iface}" = {
          ipv4.addresses = [
            {
              address = cfg.ip;
              prefixLength = 32;
            }
          ];
        };
      };
      firewall = {
        interfaces = {
          "${cfg.iface}" = {
            allowedTCPPorts = [
              services.grafana.settings.server.http_port
            ];
          };
        };
      };
    };

    # Since I forgot the password I set it originally to, to reset it manually
    # back to OG config:
    # cd /var/lib/grafana/conf grafana-cli admin reset-admin-password admin && systemctl restart grafana
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_port = 80;
          http_addr = cfg.ip;
          domain = cfg.cname;
        };
        analytics.reporting = false;
      };
    };
  };
}
