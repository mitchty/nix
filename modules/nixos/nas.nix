{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.nas;
in
{
  options.services.role.nas = {
    enable = mkEnableOption "Designate if something is/n't a nas server";

    # custom.mergerfs.balance.interval = mkOption {
    #   type = types.str;
    #   default = "weekly";
    #   example = "weekly";
    #   description = ''
    #     How often to periodically rebalance mergerfs data. Default is weekly to reduce needless i/o.

    #     The format is described in
    #     systemd.time(7).
    #   '';
    # };

    # custom.mergerfs.balance.exclude = mkOption {
    #   type = types.listof types.str;
    #   default = [];
    #   example = "[\"path\" \"path2\"]";
    #   description = ''
    #     Paths to exclude from mergerfs balancing operations.
    #   '';
    # };

    # custom.mergerfs.balance.extraArgs = mkOption {
    #   type = types.str;
    #   default = "";
    #   example = "-s 1M";
    #   description = ''
    #     Extra arguments to pass to mergerfs.balance when periodically run.
    #   '';
    # };
  };

  # TODO: extra stuff if we have other stuff enabled, for now hard coding some assumptions.
  config = mkIf cfg.enable {
    # TODO should be its own module for snapraid
    fileSystems."/snap/parity0" = {
      device = "/dev/disk/by-id/ata-ST8000NM0055-1RM112_ZA1GYY2E";
      fsType = "ext4";
      options = [ "nofail" ];
    };
    fileSystems."/snap/disk0" = {
      device = "/dev/disk/by-id/ata-ST8000NM0055-1RM112_ZA1GZD5Q";
      fsType = "ext4";
      options = [ "nofail" ];
    };
    fileSystems."/snap/disk1" = {
      device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WMAWZ0394826";
      fsType = "ext4";
      options = [ "nofail" ];
    };

    environment.systemPackages = [
      pkgs.fuse
      pkgs.mergerfs
      pkgs.mergerfs-tools
      pkgs.snapraid
      pkgs.samba
    ];

    # systemd.services.custom-mergerfs-balance =
    #   { description = "Rebalance mergerfs data perodically.";
    #     path  = [ pkgs.su ];
    #     script =
    #       ''
    #         mkdir -m 0755 -p $(dirname ${toString cfg.output})
    #         exec updatedb \
    #           --localuser=${cfg.localuser} \
    #           ${optionalString (!cfg.includeStore) "--prunepaths='/nix/store'"} \
    #           --output=${toString cfg.output} ${concatStringsSep " " cfg.extraFlags}
    #       '';
    #   };

    # systemd.timers.update-locatedb = mkIf cfg.enable
    #   { description = "Update timer for locate database";
    #     partOf      = [ "update-locatedb.service" ];
    #     wantedBy    = [ "timers.target" ];
    #     timerConfig.OnCalendar = cfg.interval;
    #   };
  };
}
