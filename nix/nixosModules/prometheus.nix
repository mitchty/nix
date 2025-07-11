{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.prometheus;
in
{
  options.services.mitchty.prometheus = {
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
      default = "";
      description = "interface to add vip to";
    };
    interval = mkOption {
      type = types.str;
      default = "10s";
      description = "scrape interval string";
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
        "--log.level=debug"
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
                "gw0.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "gw0.home.arpa";
              };
            }
            {
              targets = [
                "wm2.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "wm2.home.arpa";
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
                "rtx.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "rtx.home.arpa";
              };
            }
            {
              targets = [
                "plx.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "plx.home.arpa";
              };
            }
            {
              targets = [
                "ark.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                alias = "ark.home.arpa";
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
