{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.promtail;

  promtailConfig = {
    server = {
      grpc_listen_port = 0;
      http_listen_port = 3031;
    };

    clients = [
      { url = cfg.upstreamLoki; }
    ];

    positions = {
      filename = "/tmp/positions.yaml";
    };

    scrape_configs = [{
      job_name = "journal";
      journal = {
        max_age = "12h";
        labels = {
          job = "systemd-journal";
          host = config.networking.hostName;
        };
      };
      relabel_configs = [
        {
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }
      ];
    }];
  };

  promtailConfigFile = pkgs.writeText "promtail.json" (builtins.toJSON promtailConfig);

in
{
  options.services.role.promtail = {
    enable = mkEnableOption "Setup promtail to send logs to loki";
    upstreamLoki = lib.mkOption
      {
        type = lib.types.str;
        example = lib.literalExample "http://loki.home.arpa:3100/loki/api/v1/push";
        default = "http://loki.home.arpa:3100/loki/api/v1/push";
        description = "Url of host to send logs to";
      };
  };

  config = mkIf cfg.enable {
    systemd.services.promtail = {
      description = "promtail";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.grafana-loki}/bin/promtail --config.file ${promtailConfigFile}";
        Restart = "on-failure";
        RestartSec = "20s";
        DefaultTimeoutStopSec = "10s";
        SuccessExitStatus = 143;
        StateDirectory = "promtail";
        # DynamicUser = true;
        # User = "promtail";
        # Group = "promtail";
      };
    };
  };
}
