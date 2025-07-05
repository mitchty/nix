{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.my.media;

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
    "credentials=${config.age.secrets."secrets/cifs/plex".path}"
  ];
  fsUserMedia = [
    "uid=3000"
    "gid=3000"
  ];
  fsUserMe = [
    "uid=1000"
    "gid=100"
  ];
in
{
  options.services.my.media = {
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

  config = mkIf cfg.enable rec {
    age.secrets = {
      "secrets/cifs/plex" = {
        file = ../../secrets/cifs/plex.age;
        owner = "media";
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

    services = mkIf cfg.services rec {
      plex = {
        enable = true;
        package = pkgs.plex;
        openFirewall = true;
        group = "media";
        user = "media";
        # TODO get constant transcoder errors with stuff in here
        dataDir = "${cfg.localPrefix}/plex";
      };
      sonarr = {
        enable = true;
        openFirewall = true;
        group = "media";
        user = "media";
        dataDir = "${cfg.localPrefix}/sonarr";
        #          package = pkgs.unstable.sonarr;
      };
      radarr = {
        enable = true;
        openFirewall = true;
        group = "media";
        user = "media";
        dataDir = "${cfg.localPrefix}/radarr";
      };
      prowlarr = {
        enable = true;
        openFirewall = true;
      };
      # TODO Get a lot of sqlite3 lock errors with sabnzbd on samba,
      # so keep it local and keep the completed folder in samba
      # instead
      sabnzbd = {
        openFirewall = true;
        enable = true;
        group = "media";
        user = "media";
        configFile = "${cfg.localPrefix}/sabnzbd/sabnzbd.ini";
      };
    };

    systemd.services.plex = mkIf cfg.services rec {
      requires = [
        "nas-media.mount"
        #          "nas-internets.mount"
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
      # "/nas/media" = {
      #   device = "//s1.home.arpa/media";
      #   fsType = "cifs";
      #   options = [
      #     "user"
      #     "uid=3000"
      #     "gid=3000"
      #     "forceuid"
      #     "forcegid"
      #     "hard"
      #     "rw"
      #     "credentials=${config.age.secrets."cifs/plex".path}"
      #   ];
      # };
      # "/nas/internets" = {
      #   device = "//s1.home.arpa/internets";
      #   fsType = "cifs";
      #   options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMedia;
      # };
      # "/nas/mitch/bitbucket" = {
      #   device = "//s1.home.arpa/bitbucket";
      #   fsType = "cifs";
      #   options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      # };
      # "/nas/mitch/media" = {
      #   device = "//s1.home.arpa/media";
      #   fsType = "cifs";
      #   options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      # };
      # "/nas/mitch/backup" = {
      #   device = "//s1.home.arpa/backup";
      #   fsType = "cifs";
      #   options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      # };
    };
  };
}
