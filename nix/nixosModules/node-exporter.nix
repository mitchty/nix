{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.node-exporter;

  hasFileSystemType = fsType: { } != filterAttrs (n: v: v.fsType == fsType) config.fileSystems;

  #  iface = "enp2s0";
in
{
  options.services.mitchty.node-exporter = {
    enable = mkEnableOption "Setup as a prometheus node-exporter";

    iface = lib.mkOption {
      type = lib.types.str;
      example = lib.literalExample "eno1";
      default = "";
      description = "interface to open node exporter firewall for node exporter";
    };
  };

  config = mkIf true rec {
    networking.firewall = mkIf (cfg.iface != "") {
      interfaces = {
        "${cfg.iface}" = {
          allowedTCPPorts = [ 9002 ];
        };
      };
    };

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
          ]
          ++ (optionals (hasFileSystemType "btrfs") [ "btrfs" ])
          ++ (optionals (hasFileSystemType "xfs") [ "xfs" ]);
          port = 9002;
        };
      };
    };
  };
}
