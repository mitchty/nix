{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.node-exporter;
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
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
    };
  };
}