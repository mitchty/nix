{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.media;

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
      # default = "/s3/config";
      default = "/var/lib/media";
      type = types.path;
      example = literalExpression ''
        /some/path
      '';
      description = lib.mkDoc ''
        Specify the base path to use for configuration setups.
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
          dataDir = "${cfg.prefix}/plex";
        };
        sonarr = {
          enable = true;
          openFirewall = true;
          group = "media";
          user = "media";
          dataDir = "${cfg.prefix}/sonarr";
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
        sabnzbd = {
          enable = true;
          group = "media";
          user = "media";
          configFile = "${cfg.prefix}/sabnzbd/sabnzbd.ini";
        };

      };

      systemd.tmpfiles.rules = [
        "d ${cfg.prefix} 0755 media media"
        # Lets not keep s3fs cached crap around tooo long these files aren't that small.
        "d /tmp/s3 - - - 1d"
      ];

      systemd.services.radarr = mkIf cfg.services rec{
        requires = [ "s3-radarr.mount" ];
      };

      systemd.services.sonarr = mkIf cfg.services rec{
        requires = [ "s3-sonarr.mount" ];
      };

      systemd.services.plex = mkIf cfg.services rec{
        requires = [ "s3-tv.mount" "s3-movies.mount" "s3-media.mount" ];
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
      };

      fileSystems = {
        "/sshfs/media" = {
          device = "${pkgs.sshfs}/bin/sshfs#root@dfs1.home.arpa:/srv/media/";
          fsType = "fuse";
          options = [
            "_netdev"
            "users"
            "idmap=user"
            "IdentityFile=/root/.ssh/id_ed25519"
            "allow_other"
            "default_permissions"
            "uid=3000"
            "gid=3000"
            "exec"
            "reconnect"
            "ServerAliveInterval=15"
            "ServerAliveCountMax=3"
          ];
        };
        "/s3/media" = {
          device = "/sshfs/media";
          fsType = "none";
          options = [ "bind" "nofail" ];
        };
        "/s3/radarr" = {
          device = "/sshfs/media/movies";
          fsType = "none";
          options = [ "bind" "nofail" ];
        };
        "/s3/movies" = {
          device = "/sshfs/media/movies";
          fsType = "none";
          options = [ "bind" "nofail" ];
        };
        "/s3/sonarr" = {
          device = "/sshfs/media/tv";
          fsType = "none";
          options = [ "bind" "nofail" ];
        };
        "/s3/tv" = {
          device = "/sshfs/media/tv";
          fsType = "none";
          options = [ "bind" "nofail" ];
        };
        # "/s3/general" = {
        #   device = "${pkgs.s3fs}/bin/s3fs#general-s3fs:/";
        #   fsType = "fuse";
        #   noCheck = true;
        #   options = [
        #     "_netdev"
        #     # "curldbg"
        #     "passwd_file=${config.age.secrets."s3/bucket-general".path}"
        #     "allow_other"
        #     "mp_umask=022"
        #     "max_dirty_data=102400"
        #     "uid=1000"
        #     "gid=100"
        #     "url=http://cluster.home.arpa:3900"
        #     # "bucket=general-s3fs"
        #     "use_path_request_style"
        #   ];
        # };
        # "/s3/config" = {
        #   device = "${pkgs.s3fs}/bin/s3fs#config-s3fs:/";
        #   fsType = "fuse";
        #   noCheck = true;
        #   options = [
        #     "_netdev"
        #     # "curldbg"
        #     "passwd_file=${config.age.secrets."s3/bucket-config".path}"
        #     "allow_other"
        #     "url=http://cluster.home.arpa:3900"
        #     # "bucket=general-s3fs"
        #     "use_path_request_style"
        #   ];
        # };
        #        "/s3/media" = {
        #          device = "${pkgs.s3fs}/bin/s3fs#media-s3fs:/";
        #          fsType = "fuse";
        #          noCheck = true;
        #          options = [
        #            "_netdev"
        #            "curldbg"
        #            "passwd_file=${config.age.secrets."s3/bucket-media".path}"
        #            "allow_other"
        #            "mp_umask=022"
        #            "max_dirty_data=102400"
        #            "uid=3000"
        #            "gid=3000"
        #            "url=http://cluster.home.arpa:3900"
        #            # "bucket=general-s3fs"
        #            "use_path_request_style"
        #          ];
        #        };
        # "/s3/movies" = {
        #   device = "${pkgs.s3fs}/bin/s3fs#media-s3fs:/movies";
        #   fsType = "fuse";
        #   noCheck = true;
        #   options = [
        #     "_netdev"
        #     "curldbg"
        #     "passwd_file=${config.age.secrets."s3/bucket-media".path}"
        #     "allow_other"
        #     "mp_umask=022"
        #     "uid=3000"
        #     "gid=3000"
        #     "url=http://cluster.home.arpa:3900"
        #     # "bucket=general-s3fs"
        #     "use_path_request_style"
        #   ];
        # };
        # "/s3/tv" = {
        #   device = "${pkgs.s3fs}/bin/s3fs#media-s3fs:/tv";
        #   fsType = "fuse";
        #   noCheck = true;
        #   options = [
        #     "_netdev"
        #     "curldbg"
        #     "passwd_file=${config.age.secrets."s3/bucket-media".path}"
        #     "allow_other"
        #     "mp_umask=022"
        #     "uid=3000"
        #     "gid=3000"
        #     "url=http://cluster.home.arpa:3900"
        #     # "bucket=general-s3fs"
        #     "use_path_request_style"
        #   ];
        # };
        # "/s3/sonarr" = {
        #   device = "${pkgs.s3fs}/bin/s3fs#media-s3fs:/tv";
        #   fsType = "fuse";
        #   noCheck = true;
        #   options = [
        #     "_netdev"
        #     "curldbg"
        #     "passwd_file=${config.age.secrets."s3/bucket-media".path}"
        #     "allow_other"
        #     "mp_umask=022"
        #     "uid=3000"
        #     "gid=3000"
        #     "url=http://cluster.home.arpa:3900"
        #     "use_path_request_style"
        #     "max_dirty_data=102400"
        #     "parallel_count=5"
        #     "nomultipart" # TODO: Since I am seeing http 400's after the second part is uploaded, fuck multipart uploads on garage I guess?
        #     #            "use_cache=/tmp/s3"
        #   ];
        # };
        # "/s3/radarr" = {
        #   device = "${pkgs.s3fs}/bin/s3fs#media-s3fs:/movies";
        #   fsType = "fuse";
        #   noCheck = true;
        #   options = [
        #     "_netdev"
        #     "curldbg"
        #     "passwd_file=${config.age.secrets."s3/bucket-media".path}"
        #     "allow_other"
        #     "mp_umask=022"
        #     "uid=3000"
        #     "gid=3000"
        #     "url=http://cluster.home.arpa:3900"
        #     "use_path_request_style"
        #     "max_dirty_data=102400"
        #     "parallel_count=5"
        #     "nomultipart" # TODO: Since I am seeing http 400's after the second part is uploaded, fuck multipart uploads on garage I guess?
        #     #            "use_cache=/tmp/s3"
        #   ];
        #        };
        # "/s3/s3fs" = {
        #   device = "${pkgs.s3fs}/bin/s3fs#media-s3fs:/";
        #   fsType = " fuse ";
        #   noCheck = true;
        #   options = [
        #     "
        #     endpoint=garage"
        #     "passwd_file=${config.age.secrets."s3/bucket-media".path}"
        #     "_netdev"
        #     "curldbg"
        #     "dbglevel=debug"
        #     "sigv4"
        #     "allow_other"
        #     "mp_umask=022"
        #     "uid=3000"
        #     "gid=3000"
        #     "url=http://cluster.home.arpa:3900"
        #     "use_path_request_style"
        #     "list_object_max_keys=10000"
        #     "parallel_count=2"
        #     "nomultipart"
        #     # "multipart_size=10240"
        #     # "multipart_copy_size=10240"
        #     "use_cache=/tmp/s3"
        #     # "update_parent_dir_stat"
        #     # "streamupload" # needs 1.92 23.05 has 1.91 sigh
        #   ];
        # };
        # "/s3/rclone" = {
        #   device = "${pkgs.rclone}/bin/rclone#config-s3fs:/";
        #   fsType = "fuse";
        #   noCheck = true;
        #   options = [
        #     "_netdev"
        #     "allow_other"
        #     "--mp_umask=022"
        #     "--uid=3000"
        #     "--gid=3000"
        #     "url=http://cluster.home.arpa:3900"
        #   ];
        # };
      };
    };
}
