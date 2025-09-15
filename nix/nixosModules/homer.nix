{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.homer;
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
      default = "enp88s0";
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
              prefixLength = 32;
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
          #              logo = "assets/icons/logo.png";
          header = false;
          footer = false;
          columns = "3";
          connectivityCheck = true;

          defaults = {
            layout = "columns";
            colorTheme = "auto";
          };

          theme = "default";

          # message = {
          #   style = "is-warning";
          #   title = "dum dum reminder!";
          #   icon = "fa fa-exclamation-triangle";
          #   content = "DO NOT COMMIT THIS AS-IS FIGURE OUT ICONS AND API KEY SECRETS FIRST DUMASS";
          # };

          # icon data/name/string is from here https://fontawesome.com/search?q=tv&o=r
          links = [
            {
              name = "grafana";
              icon = "fas fa-chart-line";
              url = "http://grafana.home.arpa/d/rYdddlPWk/node-exporter-full";
              target = "_blank";
            }
            {
              name = "karakeep";
              icon = "fas fa-book";
              url = "http://karakeep.home.arpa:3000";
              target = "_blank";
            }
            {
              name = "pikvm";
              icon = "fas fa-tv";
              url = "http://pikvm.home.arpa";
              target = "_blank";
            }
            {
              name = "pikvm2";
              icon = "fas fa-tv";
              url = "http://pikvm2.home.arpa";
              target = "_blank";
            }
            {
              name = "nas";
              icon = "fas fa-tv";
              url = "https://s1.home.arpa:5001/#/signin";
              target = "_blank";
            }
            {
              name = "wiffy";
              icon = "fas fa-tv";
              url = "https://wifi.home.arpa/login";
              target = "_blank";
            }
            {
              name = "owui";
              icon = "fas fa-tv";
              url = "http://open-webui.home.arpa:8080";
              target = "_blank";
            }
            {
              name = "slowowui";
              icon = "fas fa-tv";
              url = "http://slow-open-webui.home.arpa:8080";
              target = "_blank";
            }
          ];

          services = [
            {
              name = "utils";
              icon = "fas fa-code-branch";
              items = [
                {
                  type = "SABnzbd";
                  name = "SABnzbd";
                  logo = "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/sabnzbd.svg";
                  tag = "utils";
                  keywords = "self hosted SABnzbd";
                  url = "http://media.home.arpa:8080/";
                  target = "_blank";
                  legacyApi = true;
                  apikey = "${builtins.readFile ../../crypt/tokens/sabnzbd}";
                  downloadInterval = 5000;
                }
                {
                  type = "Radarr";
                  name = "Radarr";
                  logo = "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/radarr.svg";
                  tag = "utils";
                  keywords = "self hosted radarr";
                  url = "http://media.home.arpa:7878/";
                  target = "_blank";
                  apikey = "${builtins.readFile ../../crypt/tokens/radarr}";
                  checkInterval = 5000;
                }
                {
                  type = "Sonarr";
                  name = "Sonarr";
                  logo = "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/sonarr.svg";
                  tag = "utils";
                  keywords = "self hosted sonarr";
                  url = "http://media.home.arpa:8989/";
                  target = "_blank";
                  apikey = "${builtins.readFile ../../crypt/tokens/sonarr}";
                  checkInterval = 5000;
                }
                {
                  type = "Prowlarr";
                  name = "Prowlarr";
                  logo = "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/prowlarr.svg";
                  tag = "utils";
                  keywords = "self hosted prowlarr";
                  url = "http://media.home.arpa:9696/";
                  target = "_blank";
                  legacyApi = true;
                  apikey = "${builtins.readFile ../../crypt/tokens/prowlarr}";
                  checkInterval = 5000;
                }
              ];
            }
            #       {
            #         name = "Bills";
            #         icon = "fas fa-code-branch";
            #         items = [
            #           {
            #             type = "Prometheus";
            #             name = "Prometheus";
            #             logo = "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/prometheus.svg";
            #             url = "http://prometheus.home.arpa:9001";
            #             target = "_blank";
            #           }
            #         ];
            #       }
            # - name: "Awesome app"
            #   logo: "assets/tools/sample.png"
            #   # Alternatively a fa icon can be provided:
            #   # icon: "fab fa-jenkins"
            #   subtitle: "Bookmark example"
            #   tag: "app"
            #   keywords: "self hosted reddit" # optional keyword used for searching purpose
            #   url: "https://www.reddit.com/r/selfhosted/"
            #   target: "_blank" # optional html tag target attribute
            {
              name = "monitoring";
              icon = "fas fa-code-branch";
              items = [
                {
                  type = "Prometheus";
                  name = "Prometheus";
                  logo = "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/prometheus.svg";
                  url = "http://prometheus.home.arpa:9001";
                  target = "_blank";
                }
              ];
            }
            {
              # TODO: maybe patch in the plex support manually?
              # https://github.com/bastienwirtz/homer/compare/v25.04.1...v25.05.1#diff-fb788352a1825111a3094858a3bb9df873eeb05f761b3c3dff92be1a90b8fa51
              name = "media";
              icon = "fas fa-code-branch";
              items = [
                {
                  type = "Plex";
                  name = "Plex";
                  logo = "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/plex.svg";
                  url = "http://media.home.arpa:32400/web";
                  endpoint = "http://media.home.arpa:32400";
                  target = "_blank";
                  token = "${builtins.readFile ../../crypt/tokens/plex}";
                }
              ];
            }
          ];
        };

        virtualHost = {
          domain = "homer.home.arpa";
          nginx.enable = true;
        };
      };
      # The listen setup by services.homer is 0.0.0.0:80 which can fail if
      # anything is bound to port 80 anywhere so constrain it just to that ip.
      nginx.virtualHosts."homer.home.arpa".listen = [
        {
          addr = "10.10.10.225";
          port = 80;
        }
      ];
    };
  };
}
