{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.homer;
  homerLogos = pkgs.callPackage ../packages/homer-logos.nix { };
  # Helper function to generate logo URL path
  logoUrl = filename: "/logos/${filename}";
in
{
  options.services.mitchty.homer = {
    enable = mkEnableOption "Setup homer";
    cname = mkOption {
      type = types.str;
      default = "homer.home.arpa";
      description = "Internal dns domain to use for homer aname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.225";
      description = "ip address for homer aname";
    };
    iface = mkOption {
      type = types.str;
      default = "br0";
      description = "interface to add vip to";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      firewall.allowedTCPPorts = [ 80 ];
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
    };
    services = {
      homer = {
        enable = true;
        # Needed for plex app, but unstable still has 25.04.whatever so boooo
        package = pkgs.unstable.homer;
        settings = {
          title = "home.arpa dashboard";
          subtitle = "Homer dashboard";
          icon = "homer";
          header = false;
          footer = false;
          columns = "3";
          connectivityCheck = true;

          defaults = {
            layout = "columns";
            colorTheme = "auto";
          };

          # default/neon/walkxcode apparently
          # https://github.com/bastienwirtz/homer/tree/main/src/assets/themes
          #
          # tbh only defaults ok, neon is... eww, and the xcode thing has a background image that is meh
          theme = "default";

          # icon data/name/string is from here https://fontawesome.com/search?q=tv&o=r

          links = [
            {
              name = "monthly";
              icon = "fas fa-calendar";
              url = "http://karakeep.home.arpa:3000/dashboard/lists/vb56yq5vkocrpu4hmed49zf0";
              target = "_blank";
            }
            {
              name = "watch";
              icon = "fas fa-calendar";
              url = "http://karakeep.home.arpa:3000/dashboard/lists/dt342dfhsj3jxvkgvr67mrv0";
              target = "_blank";
            }
            {
              name = "github";
              icon = "fas fa-code-branch";
              url = "https://github.com/mitchty";
              target = "_blank";
            }
            {
              name = "leo";
              icon = "fas fa-volume-high";
              url = "https://dict.leo.org/german-english/";
              target = "_blank";
            }
            {
              name = "jisho";
              icon = "fas fa-yen-sign";
              url = "https://jisho.org/";
              target = "_blank";
            }
            {
              name = "en-pt";
              icon = "fas fa-volume-high";
              url = "https://www.linguee.com/english-portuguese";
              target = "_blank";
            }
            {
              name = "en-fr";
              icon = "fas fa-volume-high";
              url = "https://www.linguee.com/english-french";
              target = "_blank";
            }
            {
              name = "en-es";
              icon = "fas fa-volume-high";
              url = "https://www.linguee.com/english-spanish";
              target = "_blank";
            }
            {
              name = "chatgpt";
              icon = "fas fa-head-side-virus";
              url = "https://chatgpt.com";
              target = "_blank";
            }
            {
              name = "claude";
              icon = "fas fa-head-side-virus";
              url = "https://claude.ai/settings/usage";
              target = "_blank";
            }
          ];

          services = [
            {
              name = "monitoring";
              icon = "fas fa-magnifying-glass";
              items = [
                {
                  name = "Grafana";
                  logo = logoUrl "grafana.svg";
                  url = "http://grafana.home.arpa/d/rYdddlPWk/node-exporter-full";
                  target = "_blank";
                }
                {
                  name = "Loki";
                  logo = logoUrl "loki.svg";
                  url = "http://grafana.home.arpa/a/grafana-lokiexplore-app/explore?patterns=%5B%5D&from=now-15m&to=now&timezone=browser&var-lineFormat=&var-ds=851Z746nz&var-filters=&var-fields=&var-levels=&var-metadata=&var-jsonFields=&var-all-fields=&var-patterns=&var-lineFilterV2=&var-lineFilters=&var-primary_label=service_name%7C%3D~%7C.%2B";
                  target = "_blank";
                }
                {
                  type = "Prometheus";
                  name = "Prometheus";
                  logo = logoUrl "prometheus.svg";
                  url = "http://prometheus.home.arpa:9001";
                  target = "_blank";
                }
              ];
            }

            {
              name = "admin";
              icon = "fas fa-radiation";
              items = [
                {
                  name = "pikvm";
                  logo = logoUrl "pikvm.png";
                  url = "http://pikvm.home.arpa";
                  target = "_blank";
                }
                {
                  name = "nas";
                  icon = "fas fa-server";
                  url = "https://s1.home.arpa:5001/#/signin";
                  target = "_blank";
                }
                {
                  name = "wiffy";
                  icon = "fas fa-wifi";
                  url = "https://wifi.home.arpa/login";
                  target = "_blank";
                }
                {
                  name = "vaultwarden";
                  logo = logoUrl "bitwarden.svg";
                  url = "https://bw.mitchty.net/#/login";
                  target = "_blank";
                }

              ];
            }
            {
              name = "misc";
              icon = "fas fa-bookmark";
              items = [
                {
                  name = "karakeep";
                  logo = logoUrl "karakeep.png";
                  url = "http://karakeep.home.arpa:3000";
                  target = "_blank";
                }
                {
                  name = "llama-swap";
                  logo = logoUrl "llama-swap.svg";
                  url = "http://llama.home.arpa:11343";
                  target = "_blank";
                }
              ];
            }
            {
              name = "media";
              icon = "fas fa-tv";
              items = [
                {
                  type = "Plex";
                  name = "Plex";
                  logo = logoUrl "plex.svg";
                  url = "http://media.home.arpa:32400/web";
                  endpoint = "http://media.home.arpa:32400";
                  target = "_blank";
                  token = "${lib.strings.trim (builtins.readFile ../../crypt/tokens/plex)}";
                }
              ];
            }
            {
              name = "utils";
              icon = "fas fa-hammer";
              items = [
                {
                  type = "SABnzbd";
                  name = "SABnzbd";
                  logo = logoUrl "sabnzbd.svg";
                  tag = "utils";
                  keywords = "self hosted SABnzbd";
                  url = "http://media.home.arpa:8080/";
                  target = "_blank";
                  legacyApi = true;
                  apikey = "${lib.strings.trim (builtins.readFile ../../crypt/tokens/sabnzbd)}";
                  downloadInterval = 5000;
                }
                {
                  type = "Radarr";
                  name = "Radarr";
                  logo = logoUrl "radarr.svg";
                  tag = "utils";
                  keywords = "self hosted radarr";
                  url = "http://media.home.arpa:7878/";
                  target = "_blank";
                  apikey = "${lib.strings.trim (builtins.readFile ../../crypt/tokens/radarr)}";
                  checkInterval = 5000;
                }
                {
                  type = "Sonarr";
                  name = "Sonarr";
                  logo = logoUrl "sonarr.svg";
                  tag = "utils";
                  keywords = "self hosted sonarr";
                  url = "http://media.home.arpa:8989/";
                  target = "_blank";
                  apikey = "${lib.strings.trim (builtins.readFile ../../crypt/tokens/sonarr)}";
                  checkInterval = 5000;
                }
                {
                  type = "Prowlarr";
                  name = "Prowlarr";
                  logo = logoUrl "prowlarr.svg";
                  tag = "utils";
                  keywords = "self hosted prowlarr";
                  url = "http://media.home.arpa:9696/";
                  target = "_blank";
                  legacyApi = true;
                  apikey = "${lib.strings.trim (builtins.readFile ../../crypt/tokens/prowlarr)}";
                  checkInterval = 5000;
                }
              ];
            }
            {
              name = "dev";
              icon = "fas fa-code-branch";
              items = [
                {
                  type = "Gitea";
                  name = "Forgejo";
                  logo = logoUrl "gitea.svg";
                  url = "http://git.home.arpa:3000";
                }
              ];
            }
            # - name: "Awesome app"
            #   logo: "assets/tools/sample.png"
            #   # Alternatively a fa icon can be provided:
            #   # icon: "fab fa-jenkins"
            #   subtitle: "Bookmark example"
            #   tag: "app"
            #   keywords: "self hosted reddit" # optional keyword used for searching purpose
            #   url: "https://www.reddit.com/r/selfhosted/"
            #   target: "_blank" # optional html tag target attribute

          ];
        };

        virtualHost = {
          domain = "homer.home.arpa";
          nginx.enable = true;
        };
      };
      # The listen setup by services.homer is 0.0.0.0:80 which can fail if
      # anything is bound to port 80 anywhere so constrain it just to that ip.
      nginx.virtualHosts."homer.home.arpa" = {
        listen = [
          {
            addr = "10.10.10.225";
            port = 80;
          }
        ];
        # Serve the logos from the nix store
        locations."/logos/" = {
          alias = "${homerLogos}/";
          extraConfig = ''
            expires 7d;
            add_header Cache-Control "public, immutable";
          '';
        };
      };
    };
  };
}
