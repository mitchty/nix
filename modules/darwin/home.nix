{ inputs, config, lib, pkgs, ... }:

with lib;

# Mostly here for prometheus monitoring and its node exporter
let
  cfg = config.services.home;
in
{
  options = {
    services.home = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Home related shenanigans.
        '';
      };
      logDir = mkOption {
        type = types.nullOr types.path;
        default = "/Users/mitch/Library/Logs";
        example = "~/Library/Logs";
        description = ''
          Base log directory, only applicable to macos.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.prometheus-node-exporter = {
      script = ''
        exec ${pkgs.prometheus-node-exporter}/bin/node_exporter
      '';

      serviceConfig.KeepAlive = true;
      serviceConfig.StandardErrorPath = "${cfg.logDir}/prometheus-node-exporter-stderr.log";
      serviceConfig.StandardOutPath = "${cfg.logDir}/prometheus-node-exporter.log";
    };
  };
}
