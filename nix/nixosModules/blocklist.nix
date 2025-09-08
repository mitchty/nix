{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.blocklist;
in
{
  options.services.mitchty.blocklist = {
    enable = mkEnableOption "Setup updates to a dns blocklist git repo for use by things like dnsmasq and have it periodically update at runtime to keep it up to date";

    cname = mkOption {
      type = types.str;
      default = "grafana.home.arpa";
      description = "Internal dns domain to use for the loki cname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.129";
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "";
      description = "interface to add vip to";
    };
    dest = mkOption {
      type = types.str;
      default = "/var/tmp";
      description = "Directory to store blocklist checkout";
    };
  };

  config = mkIf cfg.enable rec {
    # Kick off the blocklist update service to keep the dns blocklist updated
    systemd.timers.blocklist = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15m";
        OnUnitActiveSec = "300m";
        Unit = "blocklist.service";
      };
    };

    # Clone the dns-blocklist git dir into /var/lib/blocklist or git pull it
    systemd.services.blocklist = {
      script = ''
        set -eu
        d=${cfg.dest}/blocklist
        if [ ! -d $d ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/hagezi/dns-blocklists $d
        else
          cd $d && ${pkgs.git}/bin/git pull
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
