{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.harmonia;
in
{
  options.services.mitchty.harmonia = {
    enable = mkEnableOption "Enable harmonia nix binary cache server";

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port for harmonia to listen on";
    };

    signKeyPath = mkOption {
      type = types.str;
      description = "Path to the signing private key for the cache (from crypt/)";
    };
  };

  config = mkIf cfg.enable {
    services.harmonia = {
      enable = true;
      settings = {
        bind = "[::]:${toString cfg.port}";
        priority = 50;
        max_connection_rate = 16;
        sign_key_path = cfg.signKeyPath;
      };
    };

    # Open firewall for harmonia
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
