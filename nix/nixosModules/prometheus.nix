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
      default = "5s";
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
              prefixLength = 24;
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

    # prometheus seems to come up before dns works for some reason, this hacks
    # OK. Trying to get this to start after network up is a failure idea too ye olde sleep works so whatever who cares.
    systemd.services.prometheus.serviceConfig.ExecStartPre = lib.mkBefore [
      "${pkgs.coreutils}/bin/sleep 5"
    ];

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
            # {
            #   targets = [
            #     "gw.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            #   ];
            #   labels = {
            #     alias = "gw.home.arpa";
            #   };
            # }
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
            # Needs a rebuild, think I'll sell it not sure its that useful to
            # keep around, it'll be powered off at best.
            # {
            #   targets = [
            #     "srv.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            #   ];
            #   labels = {
            #     alias = "srv.home.arpa";
            #   };
            # }
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
        # TODO: get scraping of the macbook pro working as well as the old one
        # {
        #   job_name = "macos";
        #   scrape_interval = cfg.interval;
        #   static_configs = [
        #     {
        #       targets = [
        #         "mb.home.arpa:9100"
        #       ];
        #       labels = {
        #         alias = "mb.home.arpa";
        #       };
        #     }
        #   ];
        # }
      ];
    };
  };
}
