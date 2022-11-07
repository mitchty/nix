{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.node-exporter;

  hasFileSystemType = fsType: { } != filterAttrs (n: v: v.fsType == fsType) config.fileSystems;
in
{
  options.services.role.node-exporter = {
    enable = mkEnableOption "Setup as a prometheus node-exporter";
  };

  config = mkIf cfg.enable rec {
    services.prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "conntrack"
            "diskstats"
            "entropy"
            "filefd"
            "filesystem"
            "interrupts"
            "ksmd"
            "loadavg"
            "logind"
            "mdadm"
            "meminfo"
            "netdev"
            "netstat"
            "stat"
            "systemd"
            "time"
            "vmstat"
          ] ++ (
            optionals (hasFileSystemType "xfs") [ "xfs" ]
          ) ++ (
            optionals (hasFileSystemType "zfs" || elem "zfs" config.boot.supportedFilesystems) [ "zfs" ]
          );
          port = 9002;
        };
      };
    };
  };
}
