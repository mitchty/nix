{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.syncthing;
  name = "syncthing";
  label = "net.mitchty";
  fulllabel = "${label}.${name}";
in
{
  options = {
    services.${name} = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If syncthing should be enabled or not.
        '';
      };

      logDir = mkOption {
        type = types.nullOr types.path;
        default = "/Users/mitch/Library/Logs";
        example = "~/Library/Logs";
        description = ''
          Base log directory, only applicable to macos.
        '';
      };

      package = mkOption {
        default = pkgs.${name};
        defaultText = "pkgs.${name}";
        description = "Which derivation to use";
        type = types.package;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cfg.package ];
    launchd.user.agents.${fulllabel} = {
      script = ''
        #!/bin/bash
        # Note: /bin/bash so that I can add /bin/bash in security so
        # ~/Desktop... can be backed up via launchd
        #-*-mode: Shell-script; coding: utf-8;-*-
        ${pkgs.coreutils}/bin/install -Ddm755 ${cfg.logDir}/${label}/${name}
        . ${../../static/src/lib.sh}
        rotatelog 5 ${cfg.logDir}/${label}/${name}/stderr.log ${cfg.logDir}/${label}/${name}/stdout.log

        # Stop any existing daemon if present
        pkill ${name} || :

        ${cfg.package}/bin/syncthing
        exit $?
      '';
      path = [ config.environment.systemPath ];

      # low priority io cause the backup doesn't need to take precedence for any i/o operations
      serviceConfig = {
        Label = fulllabel;
        LowPriorityIO = true;
        ProcessType = "Adaptive";
        RunAtLoad = true;
        StandardErrorPath = "${cfg.logDir}/${label}/${name}/stderr.log";
        StandardOutPath = "${cfg.logDir}/${label}/${name}/stdout.log";
        StartInterval = 3600;
      };
    };
  };
}
