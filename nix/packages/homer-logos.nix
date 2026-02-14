{ pkgs, lib, ... }:

let
  # Helper to fetch a logo from a URL
  fetchLogo =
    url: hash:
    pkgs.fetchurl {
      inherit url hash;
    };

  # All the logos used in homer config
  logos = {
    grafana = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/grafana.svg" "sha256-500fQ8suX+WsWIf3H5G4btRJEu6XUnn2xjYy1QoHmdA=";
    loki = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/loki.svg" "sha256-6DJW/a+m0mry8XOaLiOwrDQHvwr47HQt/0ZDUw5ajVI=";
    prometheus = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/prometheus.svg" "sha256-rPcsgVOx7LOhxC9Kq1ma0BGncgD2KVot4e9Pfl74I5s=";
    pikvm = fetchLogo "https://raw.githubusercontent.com/pikvm/pikvm/refs/heads/master/docs/_assets/logo.png" "sha256-n0i1WjJzYfhYsRnhrhwSo+uy1jJJxEfpBJ/qe4dx0Qc=";
    bitwarden = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/bitwarden.svg" "sha256-sgoEJ4HefvVOfvGdL6RG8zOdjV2oJ94I/FjWzeXEOAY=";
    karakeep = fetchLogo "https://raw.githubusercontent.com/karakeep-app/karakeep/refs/heads/main/docs/static/img/logo.png" "sha256-1Q4MpQ+C91E7sbbo6rBtFK1xBj+c3t5VH1h7aOj2Nlc=";
    llama-swap = fetchLogo "https://raw.githubusercontent.com/mostlygeek/llama-swap/refs/heads/main/ui-svelte/public/favicon.svg" "sha256-CFL5AlzSH5N4IbBwLkyy4g/pNYqORMjnvS7fH6O16WI=";
    plex = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/plex.svg" "sha256-3k9eoZOk5+S7QkuvM6yx32jG6x9UOjpsLTVXx8PsGIU=";
    sabnzbd = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/sabnzbd.svg" "sha256-OvQTdx7TqVFOI1Qg8bC5kXhJ1DBJ5a0qwV1hXli+mIo=";
    radarr = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/radarr.svg" "sha256-OJZweLNCE+mejBjaC4TvQzbbhckpkkcEcw3bYckbLW0=";
    sonarr = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/sonarr.svg" "sha256-8d6kbFpYWkhDUjZYE0tx+qdBbzk9AOSoTC0ZqBYIgOU=";
    prowlarr = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/prowlarr.svg" "sha256-8s56gZq5Gskb7aLL4d4GmMZrSLMBRp/IIiOTphXKpLI=";
    gitea = fetchLogo "https://raw.githubusercontent.com/NX211/homer-icons/refs/heads/master/svg/gitea.svg" "sha256-SiMmD/VDLCZovb5lJU9WTew5FHBt8Q4ZtxJ/kkgE6UY=";
  };

  getExtension =
    url:
    if lib.hasSuffix ".svg" url then
      ".svg"
    else if lib.hasSuffix ".png" url then
      ".png"
    else
      "";
in
pkgs.runCommand "homer-logos" { } ''
  mkdir -p $out
  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: logo: ''
      cp ${logo} $out/${name}${getExtension logo.url}
    '') logos
  )}
''
