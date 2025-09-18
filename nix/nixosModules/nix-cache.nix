{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.nixcache;

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
  options.services.mitchty.nixcache = {
    enable = mkEnableOption "Setup nginx to cache nix http requests";
    cname = mkOption {
      type = types.str;
      default = "nixos.cache.home.arpa";
      description = "Internal dns domain to use for the http cache aname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.140";
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "enp4s0";
      description = "interface to add vip to";
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
              address = cfg.ip;
              prefixLength = 32;
            }
            {
              address = "10.10.10.142";
              prefixLength = 32;
            }
            {
              address = "10.10.10.143";
              prefixLength = 32;
            }
          ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cachePrefix} 0755 ${nginxCfg.user} ${nginxCfg.group}"
      "d ${cacheDir} 0755 ${nginxCfg.user} ${nginxCfg.group}"
      "d ${cacheDir}/nix 0755 ${nginxCfg.user} ${nginxCfg.group}"
      "d ${cacheDir}/docker 0755 ${nginxCfg.user} ${nginxCfg.group}"
      "d ${rootDir} 0755 ${nginxCfg.user} ${nginxCfg.group}"
    ];

    services.nginx =
      let
        # Note: all sizes are in mebibytes cause thats the only suffixes I can
        # use.

        # 1 GiB
        cacheClean = builtins.toString (1 * 1024 * 1024) + "m";
        # 2 TiB
        maxSize = builtins.toString (2 * 1024 * 1024 * 1024) + "m";
        # 512 GiB
        nixMaxSize = builtins.toString (128 * 1024 * 1024) + "m";
        # 256 GiB
        dockerMaxSize = builtins.toString (256 * 1024 * 1024) + "m";
      in
      {
        enable = true;

        # Keep up to a year and 2 terabytes of cache around, should be enough to
        # avoid hitting the upstream too often. Given nixos updates every 6 months
        # maybe thats a better time frame.
        #
        # Free if we ever get to 256GiB free space if other stuff I'm running
        # fills things up.
        #  min_free=${minFree}
        appendHttpConfig = ''
          resolver 10.10.10.1 valid=300s ipv6=off ipv4=on;
          proxy_cache_path ${cacheDir}/nix levels=1:2 keys_zone=cachecache:${cacheClean} max_size=${nixMaxSize} inactive=365d use_temp_path=off;
          proxy_cache_path ${cacheDir}/docker levels=1:2 keys_zone=docker:${cacheClean} max_size=${dockerMaxSize} inactive=60d use_temp_path=off;

          map $status $cache_header {
            200     "public";
            302     "public";
            default "no-cache";
          }

          # required to avoid HTTP 411: see Issue #1486 (https://github.com/docker/docker/issues/1486)
          chunked_transfer_encoding on;

          sendfile on;
          sendfile_max_chunk 10m;
          aio on;
          directio 4m;
          tcp_nopush on;
          tcp_nodelay on;
          keepalive_timeout 65;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          map $upstream_http_docker_distribution_api_version $docker_distribution_api_version {
              default $upstream_http_docker_distribution_api_version;
              \'\'      'registry/2.0';
          }
        '';
        virtualHosts = {
          "nixos.cache.home.arpa" = {
            #          "${cfg.cname}" = {
            listen = [
              {
                addr = cfg.ip;
                port = 80;
              }

            ];
            extraConfig = ''
              set $upstream_endpoint https://cache.nixos.org;
            '';

            locations = {
              "/" = {
                root = "${rootDir}";
                extraConfig = ''
                  expires max;
                  add_header Cache-Control $cache_header always;

                  error_page 404 = @fallback;

                  # Don't bother logging the above 404.
                  log_not_found off;
                '';
              };
              "@fallback" = cacheFallbackConfig;
              "= /nix-cache-info" = cacheFallbackConfig;
            };
          };
          "cachix.cache.home.arpa" = {
            listen = [
              {
                addr = "10.10.10.141";
                port = 80;
              }
            ];
            extraConfig = ''
              set $upstream_endpoint https://cachix.org;
            '';
            locations = {
              "/" = {
                root = "${rootDir}";
                extraConfig = ''
                  expires max;
                  add_header Cache-Control $cache_header always;

                  error_page 404 = @fallback;

                  # Don't bother logging the above 404.
                  log_not_found off;
                '';
              };
              "@fallback" = cacheFallbackConfig;
              "= /nix-cache-info" = cacheFallbackConfig;
            };
          };
          "nix-community.cachix.cache.home.arpa" = {
            listen = [
              {
                addr = "10.10.10.142";
                port = 80;
              }
            ];
            extraConfig = ''
              set $upstream_endpoint https://nix-community.cachix.org;
            '';

            locations = {
              "/" = {
                root = "${rootDir}";
                extraConfig = ''
                  expires max;
                  add_header Cache-Control $cache_header always;

                  error_page 404 = @fallback;

                  # Don't bother logging the above 404.
                  log_not_found off;
                '';
              };
              "@fallback" = cacheFallbackConfig;
              "= /nix-cache-info" = cacheFallbackConfig;
            };
          };
          "docker.io.cache.home.arpa" = {
            listen = [
              {
                addr = "10.10.10.143";
                port = 80;
              }
            ];
            extraConfig = ''
              add_header 'Docker-Distribution-Api-Version' $docker_distribution_api_version always;
              set $upstream_endpoint https://registry.hub.docker.com;
            '';

            locations = {
              # TODO: needed at all?
              # "/" = {
              #   extraConfig = ''
              #     proxy_pass http://registry.hub.docker.com;
              #     proxy_redirect off;
              #     proxy_set_header Host $host;
              #     proxy_set_header X-Real-IP $remote_addr;
              #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              #     proxy_set_header X-Forwarded-Host $server_name;
              #     expires max;
              #     add_header Cache-Control $cache_header always;

              #     error_page 404 = @fallback;

              #     # Don't bother logging the above 404.
              #     log_not_found off;
              #   '';
              # };

              "/token" = {
                extraConfig = ''
                  proxy_pass https://auth.docker.io/token;
                  proxy_set_header Host auth.docker.io;
                '';
              };
              "~^/v2/.*/blobs/" = {
                extraConfig = ''
                  proxy_pass https://registry-1.docker.io;
                  proxy_set_header Host registry-1.docker.io;

                  proxy_cache docker;
                  proxy_cache_key "$request_method|$request_uri";
                  proxy_ignore_headers Set-Cookie;
                  proxy_hide_header Set-Cookie;
                  proxy_cache_valid 200 301 302 30d;
                  proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
                  add_header X-Cache-Status $upstream_cache_status;
                  proxy_cache_bypass $http_authorization;
                  proxy_no_cache $http_authorization;

                  proxy_intercept_errors on;
                  error_page 307 = @handle_redirect;
                '';
              };

              "@handle_redirect" = {
                extraConfig = ''
                  internal;

                  set $redirect_url $upstream_http_location;

                  if ($redirect_url ~* ^https?://([^/]+)(/[^?]*)(\?.*)?$) {
                      set $redirect_host $1;
                      set $redirect_path $2;
                      set $redirect_args $3;
                  }

                  proxy_pass https://$redirect_host$redirect_path$redirect_args;
                  proxy_set_header Host $redirect_host;

                  proxy_cache docker;
                  # Same key as above so we cache the /v2/blah/blah/sha256:whatever the same in the 307 redir as above
                  proxy_cache_key "$request_method|$redirect_path";  # ignore host
                  proxy_ignore_headers Set-Cookie;
                  proxy_hide_header Set-Cookie;
                  proxy_cache_valid 200 30d;
                  add_header X-Cache-Status $upstream_cache_status;
                '';
              };

              # Don’t cache manifests (tags change em so best to go back to upstream for this)
              "~^/v2/.*/manifests/" = {
                extraConfig = ''
                  proxy_pass https://registry-1.docker.io;
                  proxy_set_header Host registry-1.docker.io;
                '';
              };

              # Fallback for other v2 requests not sure if needed.
              "/v2/" = {
                extraConfig = ''
                  proxy_pass https://registry-1.docker.io;
                  proxy_set_header Host registry-1.docker.io;
                '';
              };
              "@fallback" = cacheFallbackConfig;
            };
          };
        };
      };
  };
}
