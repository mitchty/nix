{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.ociregistry;
in
{
  options.services.mitchty.ociregistry = {
    enable = mkEnableOption "ociregistry OCI distribution server";

    package = mkOption {
      type = types.package;
      default = pkgs.ociregistry;
      defaultText = literalExpression "pkgs.ociregistry";
      description = "The ociregistry package to use";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "The port to serve on";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "The IP address to bind to (via OCIREGISTRY_BIND_ADDR env var)";
    };

    imagePath = mkOption {
      type = types.str;
      default = "/var/lib/ociregistry";
      description = "The path for the image cache";
    };

    logLevel = mkOption {
      type = types.enum [
        "debug"
        "info"
        "warn"
        "error"
      ];
      default = "info";
      description = "Sets the minimum value for logging";
    };

    logFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Log to the specified file rather than the console";
    };

    arch = mkOption {
      type = types.str;
      default = "amd64";
      description = "The architecture to pull images for";
    };

    os = mkOption {
      type = types.str;
      default = "linux";
      description = "The operating system to pull images for";
    };

    pullTimeout = mkOption {
      type = types.int;
      default = 60000;
      description = "The max time to pull an image in milliseconds before timing out";
    };

    healthPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = "Port number to run a /health endpoint for liveness/readiness";
    };

    metricsPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = "Port number to enable metrics exposition";
    };

    alwaysPullLatest = mkOption {
      type = types.bool;
      default = false;
      description = "Always pulls from the upstream if an image tag is 'latest'";
    };

    airGapped = mkOption {
      type = types.bool;
      default = false;
      description = "Does not attempt to pull from an upstream if an un-cached image is requested";
    };

    defaultNamespace = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "A default namespace if none is provided";
    };

    preloadImages = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a file containing a list of image refs to preload";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.ociregistry = {
      description = "OCI Registry - pull-only, pull-through, caching OCI distribution server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig =
        let
          logFileArg = optionalString (cfg.logFile != null) "--log-file ${cfg.logFile}";
          healthPortArg = optionalString (cfg.healthPort != null) "--health ${toString cfg.healthPort}";
          metricsPortArg = optionalString (cfg.metricsPort != null) "--metrics ${toString cfg.metricsPort}";
          alwaysPullLatestArg = optionalString cfg.alwaysPullLatest "--always-pull-latest";
          airGappedArg = optionalString cfg.airGapped "--air-gapped";
          defaultNamespaceArg = optionalString (
            cfg.defaultNamespace != null
          ) "--default-ns ${cfg.defaultNamespace}";
          preloadImagesArg = optionalString (
            cfg.preloadImages != null
          ) "--preload-images ${cfg.preloadImages}";
        in
        {
          Type = "simple";
          DynamicUser = true;
          StateDirectory = "ociregistry";
          StateDirectoryMode = "0755";
          ExecStart = ''
            ${cfg.package}/bin/ociregistry \
              --log-level ${cfg.logLevel} \
              --image-path ${cfg.imagePath} \
              ${logFileArg} \
              serve \
              --port ${toString cfg.port} \
              --os ${cfg.os} \
              --arch ${cfg.arch} \
              --pull-timeout ${toString cfg.pullTimeout} \
              ${healthPortArg} \
              ${metricsPortArg} \
              ${alwaysPullLatestArg} \
              ${airGappedArg} \
              ${defaultNamespaceArg} \
              ${preloadImagesArg}
          '';
          Restart = "always";
          RestartSec = "5s";
          # Use my hack to set what ip things listen to instead of 0.0.0.0 which
          # is way too wide of a bind address.
          Environment = [ "OCIREGISTRY_BIND_ADDR=${cfg.bindAddress}" ];
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
    };

    # Be sure we open the firewall otherwise this things not that useful
    networking.firewall = mkIf cfg.enable {
      allowedTCPPorts = [
        cfg.port
      ]
      ++ optional (cfg.healthPort != null) cfg.healthPort
      ++ optional (cfg.metricsPort != null) cfg.metricsPort;
    };
  };
}
