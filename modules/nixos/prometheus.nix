{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.prometheus;
in
{
  options.services.role.prometheus = {
    enable = mkEnableOption "Setup as a prometheus server";
    cname = mkOption {
      type = types.str;
      default = "prometheus.home.arpa";
      description = "Internal dns domain to use for the loki cname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.130";
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "eno1";
      description = "interface to add vip to";
    };
  };

  config = mkIf cfg.enable rec {
    networking = {
      interfaces = {
        eno1 = {
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
          eno1 = {
            allowedTCPPorts = [
              9001
            ];
          };
        };
      };
    };

    services.prometheus = {
      enable = true;
      port = 9001;
      listenAddress = cfg.cname;
      extraFlags = [ "--web.enable-admin-api" ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
      scrapeConfigs = [
        {
          job_name = "nixos";
          static_configs = [{
            targets = [
              "gw.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              "nexus.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              "dfs1.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              "srv.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            ];
          }];
        }
        {
          job_name = "macos";
          static_configs = [{
            targets = [
              "mb.home.arpa:9100"
            ];
          }];
        }
      ];
    };
  };
}
