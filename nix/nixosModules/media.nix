{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.media;

  uid = "3000"; # media uid
  gid = "3000"; # media gid
  agePath = "secrets/cifs/plex";

  creds = config.age.secrets."secrets/cifs/plex".path;

  fsAutomountOpts = [
    "x-systemd.automount"
    "x-systemd.idle-timeout=300"
    "x-systemd.mount-timeout=60s"
    "nofail"
  ];
  fsCifsPerfOpts = [
    "bsize=8388608"
    "rsize=131072"
    #"cache=loose" # TODO need to test this between nodes
  ];
  fsCifsDefaults = [
    "user" # NB keep this above exec or you can't run scripts off this mount point
    "mfsymlinks"
    "exec"
    "nofail"
    "forceuid"
    "forcegid"
    "hard"
    "rw"
    "vers=3"
  ];
  fsUserMedia = [
    "uid=3000"
    "gid=3000"
    "credentials=${config.age.secrets."secrets/cifs/plex".path}"
  ];
  fsUserMe = [
    "uid=1000"
    "gid=100"
    "credentials=${config.age.secrets."secrets/cifs/mitch".path}"
  ];
in
{
  options.services.mitchty.media = {
    enable = mkEnableOption "Designate if this system is a media server";

    services = mkOption {
      default = true;
      type = types.bool;
      example = literalExpression ''
        true|false
      '';
      description = lib.mkDoc ''
        Start services or not (to allow for mounting things elsewhere)
      '';
    };

    prefix = mkOption {
      # default = "/var/lib/media";
      default = "/nas/media/var";
      type = types.path;
      example = literalExpression ''
        /some/path
      '';
      description = lib.mkDoc ''
        Specify the base path to use for configuration setups.
      '';
    };

    localPrefix = mkOption {
      default = "/var/lib/media";
      type = types.path;
      example = literalExpression ''
        /some/path
      '';
      description = lib.mkDoc ''
        Specify the local base path to use for configuration setups.
      '';
    };

    ip = mkOption {
      type = types.str;
      default = "10.10.10.132"; # media.home.arpa
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "eno1";
      description = "interface to add vip to";
    };

    cname = mkOption {
      type = types.str;
      default = "cache.cluster.home.arpa";
      description = "Internal dns domain to use for the cluster http cache cname";
    };

  };

  config = mkIf cfg.enable {
    age.secrets = {
      "secrets/cifs/plex" = {
        file = ../../secrets/cifs/plex.age;
        owner = "media";
      };
      "secrets/cifs/mitch" = {
        file = ../../secrets/cifs/mitch.age;
        owner = "mitch";
      };
    };

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

    users = {
      users.media = {
        isSystemUser = true;
        description = "media user";
        home = "/dev/null";
        createHome = false;
        shell = pkgs.zsh;
        group = "media";
        uid = 3000;
      };
      groups.media.gid = 3000;
    };

    services = mkIf cfg.services {
      plex = {
        enable = true;
        package = pkgs.unstable.plex;
        openFirewall = true;
        group = "media";
        user = "media";
        dataDir = "${cfg.localPrefix}/plex";
      };
      sonarr = {
        enable = true;
        package = pkgs.unstable.sonarr;
        openFirewall = true;
        group = "media";
        user = "media";
        dataDir = "${cfg.localPrefix}/sonarr";
      };
      radarr = {
        enable = true;
        package = pkgs.unstable.radarr;
        openFirewall = true;
        group = "media";
        user = "media";
        dataDir = "${cfg.localPrefix}/radarr";
      };
      prowlarr = {
        enable = true;
        package = pkgs.unstable.prowlarr;
        openFirewall = true;
      };
      # TODO Get a lot of sqlite3 lock errors with sabnzbd on samba,
      # so keep it local and keep the completed folder in samba
      # instead
      sabnzbd = {
        enable = true;
        package = pkgs.unstable.sabnzbd;
        openFirewall = true;
        group = "media";
        user = "media";
        configFile = "${cfg.localPrefix}/sabnzbd/sabnzbd.ini";
      };
    };

    systemd.services.plex = mkIf cfg.services {
      requires = [
        "nas-media.mount"
        "srv-media.mount"
      ];
    };

    #10.10.10.132
    # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/nixos/modules/services/misc/prowlarr.nix
    # lacks a way to set the directory to use for data and set a user so we'll
    # just do it ourselves.
    systemd.services.prowlarr = mkIf cfg.services {
      serviceConfig = lib.mkForce {
        DynamicUser = false;
        ExecStart = "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=${cfg.localPrefix}/prowlarr";
        User = "media";
        Group = "media";
      };
    };

    fileSystems = {
      "/nas/media" = {
        device = "//s1.home.arpa/media";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMedia;
      };
      "/nas/isos" = {
        device = "//s1.home.arpa/isos";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
      "/nas/bitbucket" = {
        device = "//s1.home.arpa/bitbucket";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
    }
    // inputs.self.lib.mkCifsMount rec {
      prefix = "/srv";
      mountpoint = "media";
      share = "media";
      inherit uid gid creds;
    };
  };
}
