{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.nixcache;

  nginxCfg = config.services.nginx;

  cacheFallbackConfig = {
    proxyPass = "$upstream_endpoint";
    extraConfig = ''
      proxy_http_version 1.1;
      proxy_set_header Connection "";
      proxy_set_header Host $proxy_host;
      proxy_cache cachecache;
      proxy_cache_valid 200 302 60m;
      proxy_cache_valid 404 1m;

      expires max;
      add_header Cache-Control $cache_header always;
    '';
  };

  cachePrefix = "/var/cache/nginx";
  cacheDir = "${cachePrefix}/cache";
  rootDir = "${cachePrefix}/root";
in
{
  options.services.role.nixcache = {
    enable = mkEnableOption "Setup nginx to cache nix http requests";
    cname = mkOption {
      type = types.str;
      default = "nixcache.home.arpa";
      description = "Internal dns domain to use for the http cache cname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.131";
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "enp142s0";
      description = "interface to add vip to";
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
    };

    systemd.tmpfiles.rules = [
      "d ${cachePrefix} 0755 ${nginxCfg.user} ${nginxCfg.group}"
      "d ${cacheDir} 0755 ${nginxCfg.user} ${nginxCfg.group}"
      "d ${rootDir} 0755 ${nginxCfg.user} ${nginxCfg.group}"
    ];

    services.nginx = {
      enable = true;

      appendHttpConfig = ''
        proxy_cache_path ${cacheDir} levels=1:2 keys_zone=cachecache:100m max_size=100g inactive=60d use_temp_path=off;

        map $status $cache_header {
          200     "public";
          302     "public";
          default "no-cache";
        }
      '';

      virtualHosts."${cfg.cname}" = {
        listen = [
          { addr = cfg.ip; port = 80; }
          { addr = cfg.ip; port = 443; }
        ];
        extraConfig = ''
          resolver 10.10.10.1 valid=10s;
          set $upstream_endpoint https://cache.nixos.org;
        '';

        locations."/" =
          {
            root = "${rootDir}";
            extraConfig = ''
              expires max;
              add_header Cache-Control $cache_header always;

              error_page 404 = @fallback;

              # Don't bother logging the above 404.
              log_not_found off;
            '';
          };

        locations."@fallback" = cacheFallbackConfig;
        locations."= /nix-cache-info" = cacheFallbackConfig;
      };
    };
  };
}
