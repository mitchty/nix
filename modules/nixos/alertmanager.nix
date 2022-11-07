{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.alertmanager;
in
{
  options.services.role.alertmanager = {
    enable = mkEnableOption "Setup as an alertmanager server";
    cname = mkOption {
      type = types.str;
      default = "alertmanager.home.arpa";
      description = "Internal dns domain to use for the alertmanager cname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.132";
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
              9003
            ];
          };
        };
      };
    };

    alertmanager = {
      enable = true;
      listenAddress = cfg.ip;
      configuration = {
        "global" = {
          "smtp_smarthost" = "smtp.example.com:587";
          "smtp_from" = "alertmanager@example.com";
        };
        "route" = {
          "group_by" = [ "alertname" "alias" ];
          "group_wait" = "30s";
          "group_interval" = "30m";
          "repeat_interval" = "8h";
          "receiver" = "stopbeinglazy";
        };
        "receivers" = [
          {
            "name" = "stopbeinglazy";
            "email_configs" = [
              {
                "to" = "alerts@mitchty.net";
                "send_resolved" = true;
              }
            ];
            # "webhook_configs" = [
            #   {
            #     "url" = "https://example.com/prometheus-alerts";
            #     "send_resolved" = true;
            #   }
            # ];
          }
        ];
      };
    };
  };
}
