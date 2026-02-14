{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.ncps;
in
{
  options.services.mitchty.ncps = {
    enable = mkEnableOption "Setup ncps nix cache proxy server";
    nixCname = mkOption {
      type = types.str;
      default = "nix.cache.home.arpa";
      description = "Internal dns domain to use for the http cache aname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    nixIp = mkOption {
      type = types.str;
      default = "10.10.10.140";
      description = "ip address for cache.nixos.org";
    };
    dockerCname = mkOption {
      type = types.str;
      default = "docker.io.cache.home.arpa";
      description = "Internal dns domain to use for the http cache aname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    dockerIp = mkOption {
      type = types.str;
      default = "10.10.10.141";
      description = "ip address for docker.io";
    };
    iface = mkOption {
      type = types.str;
      default = "enp4s0";
      description = "interface to add vips to";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      firewall.allowedTCPPorts = [
        80
        443
      ];
      interfaces = {
        "${cfg.iface}" = {
          ipv4.addresses = [
            {
              address = cfg.nixIp;
              prefixLength = 24;
            }
            {
              address = cfg.dockerIp;
              prefixLength = 24;
            }
          ];
        };
      };
    };

    # ncps is abused for doing nix caching for cachix et al, was simpler than
    # the nginx hack and work with cachix which I was having annoying issues
    # with.
    services.ncps = {
      enable = true;
      package = pkgs.ncps;
      cache = {
        hostName = cfg.nixCname;
        maxSize = "256G";
        # Clean cache every week tops
        lru.schedule = "1 7 * * 1";
      };
      server.addr = "${cfg.nixIp}:8080";
      upstream = {
        caches = [
          "http://rtx.home.arpa:5000"
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        publicKeys = [
          "${builtins.readFile ../../crypt/nix/publickey}"
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
  };
}
