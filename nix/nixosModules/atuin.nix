{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.atuin;
in
{
  options.services.mitchty.atuin = {
    enable = mkEnableOption "Setup atuin sync server";
    cname = mkOption {
      type = types.str;
      default = "atuin.home.arpa";
      description = "Internal dns domain to use for the atuin server";
    };
    ip = mkOption {
      type = types.str;
      default = "10.10.10.135";
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "";
      description = "interface to add vip to";
    };
    port = mkOption {
      type = types.port;
      default = 8888;
      description = "Port for atuin server to listen on";
    };
  };

  config = mkIf cfg.enable {
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
              cfg.port
            ];
          };
        };
      };
    };

    services.atuin = {
      inherit (cfg) port;
      enable = true;
      # Default off only here to enable first/only user
      #openRegistration = true;
      host = cfg.ip;
      database = {
        createLocally = true;
        uri = "postgresql:///atuin?host=/run/postgresql";
      };

      maxHistoryLength = 102400;
    };
  };
}
