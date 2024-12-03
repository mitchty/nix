{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.media;

  fsAutomountOpts = [
    "x-systemd.automount"
    "nofail"
    "x-systemd.idle-timeout=300"
    "x-systemd.mount-timeout=60s"
  ];
  fsCifsPerfOpts = [
    "bsize=8388608"
    "rsize=130048"
    #"cache=loose" # TODO need to test this between nodes
  ];
  fsCifsDefaults = [
    "user"
    "forceuid"
    "forcegid"
    "hard"
    "rw"
    "vers=3"
    "credentials=${config.age.secrets."cifs/plex".path}"
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
  options.services.role.media = {
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


    cname = mkOption {
      type = types.str;
      default = "cache.cluster.home.arpa";
      description = "Internal dns domain to use for the cluster http cache cname";
    };
  };

  config = mkIf cfg.enable
    rec {
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
        };
        radarr = {
          enable = true;
          openFirewall = true;
          group = "media";
          user = "media";
          dataDir = "${cfg.prefix}/radarr";
        };
        prowlarr = {
          enable = true;
          openFirewall = true;
        };
        # TODO Get a lot of sqlite3 lock errors with sabnzbd on samba,
        # so keep it local and keep the completed folder in samba
        # instead
        sabnzbd = {
          enable = true;
          group = "media";
          user = "media";
          configFile = "${cfg.localPrefix}/sabnzbd/sabnzbd.ini";
        };
      };

      systemd.services.radarr = mkIf cfg.services rec{
        requires = [
          "nas-media.mount"
        ];
      };

      systemd.services.sonarr = mkIf cfg.services rec{
        requires = [
          "nas-media.mount"
        ];
      };

      systemd.services.plex = mkIf cfg.services rec{
        requires = [
          "nas-media.mount"
        ];
      };

      #10.10.10.132
      # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/nixos/modules/services/misc/prowlarr.nix
      # lacks a way to set the directory to use for data and set a user so we'll
      # just do it ourselves.
      systemd.services.prowlarr = mkIf cfg.services {
        serviceConfig = lib.mkForce {
          DynamicUser = false;
          ExecStart = "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=${cfg.prefix}/prowlarr";
          User = "media";
          Group = "media";
        };
        requires = [
          "nas-media.mount"
        ];
      };

      fileSystems = {
        "/nas/media" = {
          device = "//s1.home.arpa/media";
          fsType = "cifs";
          options = [
            "user"
            "uid=3000"
            "gid=3000"
            "forceuid"
            "forcegid"
            "hard"
            "rw"
            "credentials=${config.age.secrets."cifs/plex".path}"
          ];
        };
        "/nas/internets" = {
          device = "//s1.home.arpa/internets";
          fsType = "cifs";
          options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMedia;
        };
        "/nas/mitch/internets" = {
          device = "//s1.home.arpa/internets";
          fsType = "cifs";
          options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
        };
        "/nas/mitch/media" = {
          device = "//s1.home.arpa/media";
          fsType = "cifs";
          options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
        };
      };
    };
}
