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
    interval = mkOption {
      type = types.str;
      default = "10s";
      description = "scrape intrerval string";
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
      # https://prometheus.io/docs/prometheus/latest/storage/#operational-aspects
      extraFlags = [
        "--web.enable-admin-api"
        "--storage.tsdb.wal-compression"
        "--storage.tsdb.retention.time=${toString (365 * 3)}d" # 3 years of data?
      ];
      scrapeConfigs = [
        {
          job_name = "nixos";
          scrape_interval = cfg.interval;
          static_configs = [
            {
              targets = [
                "gw.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "gw.home.arpa";
              };
            }
            {
              targets = [
                "nexus.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "nexus.home.arpa";
              };
            }
            {
              targets = [
                "dfs1.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "dfs1.home.arpa";
              };
            }
            {
              targets = [
                "srv.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "srv.home.arpa";
              };
            }
            {
              targets = [
                "cl1.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "cl1.home.arpa";
              };
            }
            {
              targets = [
                "cl2.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "cl2.home.arpa";
              };
            }
          ];
        }
        {
          job_name = "macos";
          scrape_interval = cfg.interval;
          static_configs = [
            {
              targets = [
                "mb.home.arpa:9100"
              ];
              labels = {
                alias = "mb.home.arpa";
              };
            }
          ];
        }
      ];
    };
  };
}
